import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../db/firebase_helper.dart';
import '../models/match.dart';
import '../models/user_strokes.dart';
import 'hole_screen.dart';

class ScoreCardScreen extends StatelessWidget {
  final Match _match;

  const ScoreCardScreen(this._match);

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<Match>(
      stream: FirebaseHelper.getMatch(_match.id),
      builder: (context, snapshot) {
        final match = snapshot.data ?? _match;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DataTable(
                      showCheckboxColumn: false,
                      columns: [
                        DataColumn(label: Container()),
                        ...List.generate(
                          userStrokesList.length,
                          (index) {
                            final user = userStrokesList[index].user;
                            return DataColumn(
                              label: Expanded(
                                child: Text(
                                  user.username,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      rows: [
                        ...match.course.pars.asMap().entries.map((e) {
                          final par = e.value;
                          return DataRow(
                            onSelectChanged: (_) {
                              // Navigate to the selected hole
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) {
                                  return HoleScreen(
                                    match,
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
                                      style:
                                          Theme.of(context).textTheme.bodyText1,
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
                                  if (strokeCount == 0 || strokeCount == par) {
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
                                  Text('(Par ${match.course.parTotal})'),
                                ],
                              ),
                            ),
                            ...List.generate(userStrokesList.length, (index) {
                              String text =
                                  userStrokesList[index].getScoreSummary(match);

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
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_match.course.name),
        actions: [
          // IconButton(
          //   onPressed: () {},
          //   icon: Icon(Icons.person_add_alt),
          // ),
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

  void _showAddUserSheet(BuildContext context, String matchId) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      builder: (context) {
        return Center(
          child: FractionallySizedBox(
            child: QrImage(data: matchId),
            widthFactor: 0.5,
          ),
        );
      },
    );
  }
}
