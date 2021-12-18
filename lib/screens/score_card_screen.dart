import 'package:disc_golf/models/user.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../db/firebase_helper.dart';
import '../models/match.dart';
import '../models/user_strokes.dart';
import 'hole_screen.dart';

class ScoreCardScreen extends StatefulWidget {
  final Match _match;

  const ScoreCardScreen(this._match);

  @override
  State<ScoreCardScreen> createState() => _ScoreCardScreenState();
}

class _ScoreCardScreenState extends State<ScoreCardScreen> {
  late Match _match;

  @override
  void initState() {
    super.initState();
    _match = widget._match;
  }

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<Match>(
      stream: FirebaseHelper.getMatch(_match.id),
      builder: (context, snapshot) {
        _match = snapshot.data ?? _match;

        return StreamBuilder<Iterable<UserStrokes>>(
          stream: FirebaseHelper.getUserStrokesForMatch(_match.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            final userStrokesList = snapshot.data?.toList();
            if (userStrokesList == null) {
              return Center(
                child: Text(':('),
              );
            }
            return SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DataTable(
                        showCheckboxColumn: false,
                        columnSpacing: 56 / 3, // Default is 56
                        columns: [
                          DataColumn(label: Container()),
                          ...List.generate(
                            userStrokesList.length,
                            (index) {
                              final user = userStrokesList[index].user;

                              return DataColumn(
                                label: TextButton(
                                  onPressed: null,
                                  onLongPress: user.isOfflinePlayer()
                                      ? () => _showRemoveOfflinePlayerDialog(
                                          context, user)
                                      : null,
                                  child: Text(
                                    user.username,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        rows: [
                          ..._match.course.pars.asMap().entries.map((e) {
                            final par = e.value;
                            return DataRow(
                              onSelectChanged: (_) {
                                // Navigate to the selected hole
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) {
                                    return HoleScreen(
                                      _match,
                                      initialPage: e.key,
                                    );
                                  },
                                ));
                              },
                              cells: [
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Hole ${e.key + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1,
                                      ),
                                      Text('(Par ${e.value})'),
                                    ],
                                  ),
                                ),
                                ...List.generate(
                                  userStrokesList.length,
                                  (index) {
                                    final strokeCount =
                                        userStrokesList[index].strokes[e.key];
                                    final strokeCountStr = strokeCount == 0
                                        ? '-'
                                        : strokeCount.toString();
                                    final Color? color;
                                    if (strokeCount == 0 ||
                                        strokeCount == par) {
                                      color = null;
                                    } else if (strokeCount <= par) {
                                      color = Colors.green.withOpacity(0.5);
                                    } else {
                                      color = Colors.red.withOpacity(0.5);
                                    }

                                    return DataCell(
                                      Container(
                                        alignment: Alignment.center,
                                        color: color,
                                        child: Text(
                                          strokeCountStr,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline6,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          }).toList(),
                          DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Total',
                                      style:
                                          Theme.of(context).textTheme.bodyText1,
                                    ),
                                    Text('(Par ${_match.course.parTotal})'),
                                  ],
                                ),
                              ),
                              ...List.generate(userStrokesList.length, (index) {
                                String text = userStrokesList[index]
                                    .getScoreSummary(_match);

                                if (userStrokesList[index].incompleteScore) {
                                  text += '*';
                                }

                                return DataCell(
                                  Center(
                                    child: Text(
                                      text,
                                      style:
                                          Theme.of(context).textTheme.headline6,
                                    ),
                                  ),
                                );
                              })
                            ],
                          ),
                        ],
                      ),
                      if (userStrokesList.any((each) => each.incompleteScore))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            '* denotes an incomplete score',
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        ),
                      SizedBox(height: 68),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_match.course.name),
        actions: [
          IconButton(
            tooltip: 'Add an offline player',
            icon: Icon(Icons.person_add_alt),
            onPressed: () async {
              final users = await _showOfflinePlayerDialog(context);
              if (users == null) return;

              users.forEach((user) async {
                final result =
                    await FirebaseHelper.addOfflineUserToMatch(user, _match.id);
                if (result == false) {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          'Could not add "${user.username}" to the match.',
                        ),
                        backgroundColor: Theme.of(context).errorColor,
                      ),
                    );
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.qr_code),
            tooltip: 'Share game via QR code',
            onPressed: () {
              _showAddUserSheet(context, _match.id);
            },
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) {
              return HoleScreen(_match);
            },
          ));
        },
        icon: Icon(Icons.arrow_forward),
        label: Text('Go to hole 1'),
      ),
    );
  }

  Future<List<User>?> _showOfflinePlayerDialog(BuildContext context) {
    return showDialog<List<User>>(
      context: context,
      builder: (context) {
        var input = '';
        String? errorText;
        final List<User> selected = [];

        return StatefulBuilder(
          builder: (context, setState) {
            return SimpleDialog(
              title: Text('Add an offline player'),
              contentPadding: EdgeInsets.zero,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Player Name',
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      input = value;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                      'Note: If the other player has their own device, you may want to consider sharing the match via QR Code.'),
                ),
                FutureBuilder<List<User>>(
                  future: FirebaseHelper.getOfflineUsers(),
                  builder: (context, snapshot) {
                    final users = snapshot.data;
                    if (users != null) {
                      // Remove offline players already in the current match
                      final existingOfflinePlayers = _match.players.where(
                          (element) => element.startsWith(OFFLINE_PREFIX));
                      users.removeWhere((element) =>
                          existingOfflinePlayers.contains(element.id));

                      if (users.length > 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OR select a previous user:',
                                style: Theme.of(context).textTheme.bodyText1,
                              ),
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: users.take(6).map((user) {
                                  return InputChip(
                                    label: Text(user.username),
                                    selected: selected.contains(user),
                                    onSelected: (bool value) {
                                      setState(() {
                                        if (selected.contains(user)) {
                                          selected.remove(user);
                                        } else {
                                          selected.add(user);
                                        }
                                      });
                                    },
                                    // TODO: delete user from firestore collection
                                    // onDeleted: () {},
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                    return Container();
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
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
                          if (input.isNotEmpty) {
                            selected.add(User(
                                id: OFFLINE_PREFIX + input,
                                email: null,
                                imageUri: null,
                                username: input));
                          }

                          if (selected.isEmpty) {
                            setState(() {
                              errorText = 'Enter a name to add a player';
                            });
                          } else {
                            Navigator.of(context).pop(selected);
                          }
                        },
                        child: Text('Save'),
                      ),
                    ],
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future _showRemoveOfflinePlayerDialog(BuildContext context, User user) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove "${user.username}"?'),
          content: Text(
              'This will remove player "${user.username}" from this game.'),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseHelper.removeUserFromMatch(user.id, _match.id);
                Navigator.of(context).pop();
              },
              child: Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  void _showAddUserSheet(BuildContext context, String matchId) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                // BottomSheet is 1/2 of screen height, so use 1/2 of that
                maxHeight: size.height / 4,
                maxWidth: size.width / 2,
              ),
              child: QrImage(data: matchId),
            ),
            Text(matchId),
          ],
        );
      },
    );
  }
}
