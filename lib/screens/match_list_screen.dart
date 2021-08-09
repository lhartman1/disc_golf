import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../db/firebase_helper.dart';
import '../models/match.dart';
import '../utils/utils.dart' as utils;
import 'new_match_screen.dart';
import 'qr_scan_screen.dart';
import 'score_card_screen.dart';

class MatchListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Matches'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: ListTile(
                    title: Text('Logout'),
                    leading: Icon(Icons.exit_to_app),
                    onTap: () {
                      Navigator.of(context).pop();
                      FirebaseAuth.instance.signOut();
                    },
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        tooltip: 'Open menu',
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Theme.of(context).accentColor,
        children: [
          SpeedDialChild(
            child: Icon(Icons.qr_code_2),
            label: 'Join match by QR code',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  return QRScanScreen();
                },
              ));
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.post_add),
            label: 'Create a new match',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () async {
              final match =
                  await Navigator.of(context).push<Match>(MaterialPageRoute(
                builder: (context) {
                  return NewMatchScreen();
                },
              ));

              // Navigate to new match if it exists
              if (match != null) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) {
                    return ScoreCardScreen(match);
                  },
                ));
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Match>>(
        stream: FirebaseHelper.getAllMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final matches = snapshot.data;
          if (matches == null) {
            return Center(child: Text(':('));
          }

          if (matches.length == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'You don\'t have any matches yet, click the "+" button below to start or join one.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
            );
          }

          // Build matches ListView
          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];

              var clickPos = RelativeRect.fill;
              return GestureDetector(
                onLongPressStart: (details) {
                  // Store the touch position when a long press is started.
                  clickPos = RelativeRect.fromLTRB(
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                  );
                },
                onLongPress: () {
                  // Offer delete option for long pressing match
                  showMenu(context: context, position: clickPos, items: [
                    PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Remove'),
                        onTap: () {
                          FirebaseHelper.removeUserFromMatch(
                              FirebaseHelper.getUserId() ?? '<unknown>',
                              match.id);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ]);
                },
                onTap: () {
                  // Go to ScoreCard
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return ScoreCardScreen(match);
                    },
                  ));
                },
                child: Card(
                  child: ListTile(
                    title: Text(match.course.name),
                    subtitle:
                        Text(utils.dateTimeFormatter.format(match.datetime)),
                  ),
                ),
              );
            },
            padding: EdgeInsets.all(4),
          );
        },
      ),
    );
  }
}
