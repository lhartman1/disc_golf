import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/match.dart';
import '../models/user_strokes.dart';
import 'hole_screen.dart';

class ScoreCardScreen extends StatelessWidget {
  const ScoreCardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userStrokesList = context.watch<List<UserStrokes>>();
    final match = context.read<Match>();

    return Scaffold(
      appBar: AppBar(
        title: Text(match.course.name),
        actions: [
          // IconButton(
          //   onPressed: () {},
          //   icon: Icon(Icons.person_add_alt),
          // ),
          IconButton(
            icon: Icon(Icons.qr_code),
            tooltip: 'Share game via QR code',
            onPressed: () {
              _showAddUserSheet(context, match.id);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                        label: Text(user.username),
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
                              match: match,
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
                                style: Theme.of(context).textTheme.bodyText1,
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
                            final strokeCountStr =
                                strokeCount == 0 ? '-' : strokeCount.toString();
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
                                  style: Theme.of(context).textTheme.headline6,
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
                              'Totals',
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                          ],
                        ),
                      ),
                      ...List.generate(userStrokesList.length, (index) {
                        String text =
                            userStrokesList[index].strokeSum.toString();

                        if (userStrokesList[index].incompleteScore) {
                          text += '*';
                        }

                        return DataCell(
                          Center(
                            child: Text(
                              text,
                              style: Theme.of(context).textTheme.headline6,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) {
              return HoleScreen(match: match);
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
