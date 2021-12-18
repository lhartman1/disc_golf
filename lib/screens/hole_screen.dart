import 'package:flutter/material.dart';

import '../db/firebase_helper.dart';
import '../models/match.dart';
import '../models/user_strokes.dart';
import '../widgets/hole/player_hole_score.dart';

class HoleScreen extends StatefulWidget {
  final Match _match;
  final int initialPage;

  const HoleScreen(
    this._match, {
    Key? key,
    this.initialPage = 0,
  }) : super(key: key);

  @override
  State<HoleScreen> createState() => _HoleScreenState();
}

class _HoleScreenState extends State<HoleScreen> {
  late final Stream<Match> _matchStream;
  late final Stream<Iterable<UserStrokes>> _userStrokesStream;
  late int _page;
  var _isSettingOrder = false;
  late Match _match;
  List<String>? _order;

  @override
  void initState() {
    super.initState();
    _matchStream = FirebaseHelper.getMatch(widget._match.id);
    _userStrokesStream =
        FirebaseHelper.getUserStrokesForMatch(widget._match.id);
    _page = widget.initialPage;
    _match = widget._match;
  }

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: widget.initialPage);
    // Use this to get rid of last hole snackbar message
    controller.addListener(() {
      ScaffoldMessenger.of(context).clearSnackBars();

      final newPage = controller.page?.round();
      if (newPage != null && _page != newPage) {
        print('newPage: $newPage');
        setState(() {
          // FIXME: doesn't work correctly. Maybe store page sorted?
          _page = newPage;
          _order = null;
          // Turn off order setting on pages after the first one
          if (_page > 0) {
            _isSettingOrder = false;
          }
        });
      }
    });

    final body = StreamBuilder<Match>(
      stream: _matchStream,
      builder: (context, matchSnapshot) {
        return StreamBuilder<Iterable<UserStrokes>>(
          stream: _userStrokesStream,
          builder: (context, userStrokesSnapshot) {
            if (matchSnapshot.connectionState == ConnectionState.waiting ||
                userStrokesSnapshot.connectionState ==
                    ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final match = matchSnapshot.data;
            final userStrokesIterable = userStrokesSnapshot.data;
            if (match == null || userStrokesIterable == null) {
              return Center(child: Text(':('));
            }
            _match = match;

            return PageView.builder(
              scrollDirection: Axis.horizontal,
              controller: controller,
              itemCount: _match.course.numHoles,
              itemBuilder: (BuildContext context, int index) {
                return _buildCustomScrollView(
                    context, _match, userStrokesIterable, index);
              },
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(_match.course.name),
        actions: [
          if (_page == 0)
            IconButton(
              onPressed: () async {
                _isSettingOrder = !_isSettingOrder;

                if (_isSettingOrder) {
                  _order = List.from(_match.players);
                }

                if (!_isSettingOrder && _order != null) {
                  _match = _match.copyWith(players: _order);
                  _order = null;
                  print('resetting _pageSorted');
                  await FirebaseHelper.updateStartingOrder(_match);
                }

                setState(() {});
              },
              tooltip: _isSettingOrder ? 'Save starting order' : 'Set starting order',
              icon: Icon(_isSettingOrder ? Icons.save : Icons.low_priority),
            ),
        ],
      ),
      body: body,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'prev_hole',
            mini: true,
            tooltip: 'Move to previous hole',
            onPressed: () {
              final pageNumber = controller.page?.round() ?? 0;
              if (pageNumber > 0) {
                controller.previousPage(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeIn);
              } else {
                // Go back to scorecard when on the first hole
                Navigator.of(context).pop();
              }
            },
            child: Icon(Icons.arrow_back),
          ),
          SizedBox(
            width: 16,
          ),
          FloatingActionButton.extended(
            heroTag: 'next_hole',
            onPressed: () {
              final pageNumber = controller.page?.round() ?? 0;
              if (pageNumber < (_match.course.numHoles - 1)) {
                controller.nextPage(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeIn);
              } else {
                // Go back to scorecard when on the last hole
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Move to next hole',
            label: Text('Next Hole'),
            icon: Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  SliverReorderableList _buildPlayerHoleScores(
    Iterable<UserStrokes> userStrokesIterable,
    Match match,
    int index,
  ) {
    final orderList = _getTeeOrder(index, userStrokesIterable.toList());

    // The sortOrder should only be updated when the user navigates to a new
    // page or when the order is set via the UI. This is to keep the players in
    // place to prevent accidentally changing the score for the wrong player.
    final List<String> sortOrder;

    // This IF block is true when this function is executed for the active
    // PageView instead of a PageView that is only partially scrolled into view.
    // The active PageView should not reorder the users when scores on previous
    // holes change.
    if (index == _page) {
      if (_order == null) {
        _order = orderList ?? match.players;
      }
      sortOrder = _order!;
    } else {
      // This is executed when a PageView is partially scrolled into view.
      // It should ignore any existing order until it is the active PageView.
      sortOrder = orderList ?? match.players;
    }

    userStrokesIterable = userStrokesIterable.toList()
      ..sort((a, b) {
        final first = sortOrder.indexOf(a.user.id);
        final second = sortOrder.indexOf(b.user.id);
        return first.compareTo(second);
      });

    // This is the order number in the CircleAvatar and
    // ReorderableDragStartListener in PlayerHoleScore. This should be
    // up-to-date at all times, unlike sortOrder.
    final displayOrder =
        (_isSettingOrder ? _order : orderList) ?? match.players;

    final playerHoleScores = userStrokesIterable.map((e) {
      final isMe = FirebaseHelper.getUserId() == e.user.id;
      final order = displayOrder.indexOf(e.user.id);

      return PlayerHoleScore(
        key: ValueKey(e.user),
        match: match,
        userStrokes: e,
        holeIndex: index,
        editable: isMe || e.user.isOfflinePlayer(),
        settingOrder: _isSettingOrder,
        order: orderList == null ? null : order,
      );
    }).toList();

    return SliverReorderableList(
      itemCount: playerHoleScores.length,
      itemBuilder: (context, index) {
        return playerHoleScores[index];
      },
      onReorder: (int oldIndex, int newIndex) {
        print('onReorder: $oldIndex, $newIndex');
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          if (_order != null) {
            final item = _order!.removeAt(oldIndex);
            _order!.insert(newIndex, item);
          }
        });
      },
    );
  }

  CustomScrollView _buildCustomScrollView(
    BuildContext context,
    Match match,
    Iterable<UserStrokes> userStrokesIterable,
    int index,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: Container(),
          leadingWidth: 0,
          pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'HOLE ',
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                  Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                        SnackBar(content: Text('Long Press to Edit Par')));
                },
                onLongPress: () async {
                  final result = await _showParDialog(context, match, index);

                  if (result == null || result == match.course.pars[index]) {
                    return;
                  }

                  match.course.pars[index] = result;
                  FirebaseHelper.syncParsForMatch(match);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      ' PAR ',
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Text(
                      match.course.pars[index].toString(),
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildPlayerHoleScores(userStrokesIterable, match, index),
        SliverList(
          delegate: SliverChildListDelegate([
            if (_getTeeOrder(index, userStrokesIterable.toList()) == null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '* complete earlier holes to see order.',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),
            SizedBox(height: 68),
          ]),
        ),
      ],
    );
  }

  Future<int?> _showParDialog(BuildContext context, Match match, int index) {
    return showDialog<int>(
      context: context,
      builder: (context) {
        var par = match.course.pars[index];
        return StatefulBuilder(
          builder: (context, setState) {
            return SimpleDialog(
              title: Text('New par for Hole ${index + 1}'),
              contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
              children: [
                SizedBox(height: 16),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).accentColor,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (par > 1) {
                              setState(() {
                                par--;
                              });
                            }
                          },
                          icon: Icon(Icons.remove),
                        ),
                        Text(
                          par.toString(),
                          style: Theme.of(context).textTheme.headline4,
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              par++;
                            });
                          },
                          icon: Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(par);
                      },
                      child: Text('Save'),
                    ),
                    SizedBox(width: 24),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<String>? _getTeeOrder(int holeNum, List<UserStrokes> userStrokesList) {
    // The order cannot be correctly computed if any players have incomplete
    // scores for the previous holes.
    for (int i = 0; i < userStrokesList.length; i++) {
      for (int j = 0; j < holeNum; j++) {
        if (userStrokesList[i].strokes[j] == 0) {
          return null;
        }
      }
    }

    userStrokesList.sort((a, b) => _compareUserStrokes(holeNum, a, b));

    return userStrokesList.map((e) => e.user.id).toList();
  }

  int _compareUserStrokes(int hole, UserStrokes a, UserStrokes b) {
    // On the first hole, simply use the player order
    if (hole == 0) {
      final first = _match.players.indexOf(a.user.id);
      final second = _match.players.indexOf(b.user.id);
      return first.compareTo(second);
    }

    // After the first hole, compare the strokes from the previous hole
    final aScore = a.strokes[hole - 1];
    final bScore = b.strokes[hole - 1];

    if (aScore != bScore) {
      return aScore.compareTo(bScore);
    }

    // If two players have the same score on the previous hole, recursively
    // check the hole before the previous one.
    return _compareUserStrokes(hole - 1, a, b);
  }
}
