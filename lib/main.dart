import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'db/firebase_helper.dart';
import 'models/match.dart';
import 'screens/auth_screen.dart';
import 'screens/new_match_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/score_card_screen.dart';
import 'utils/utils.dart' as utils;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      // primarySwatch: Colors.lightBlue,
      // primaryColor: Colors.lightBlue[200],
      // accentColor: Colors.amberAccent,
      // scaffoldBackgroundColor: Colors.cyan[50],
      primarySwatch: Colors.orange,
      primaryColor: Color(0xffff7000),
      accentColor: Colors.amberAccent,
      scaffoldBackgroundColor: Colors.orange.shade50,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.orange,
      accentColor: Colors.amberAccent,
    );

    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error :(');
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Disc Golf',
            theme: lightTheme,
            darkTheme: darkTheme,
            home: StreamBuilder(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (userSnapshot.hasData) {
                    return HomePage();
                  }
                  return AuthScreen();
                }),
          );
        }

        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final games = FirebaseFirestore.instance
        .collection('matches')
        .where(
          'players',
          arrayContains: FirebaseHelper.getUserId() ?? '<unknown>',
        )
        .orderBy(
          'datetime',
          descending: true,
        )
        .snapshots();

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
            label: 'Join game by QR code',
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: games,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final gamesData = snapshot.data?.docs;

          if (snapshot.hasData && gamesData != null) {
            // Build matches ListView
            return ListView.builder(
              itemCount: gamesData.length,
              itemBuilder: (context, index) {
                final matchData = gamesData[index].data();
                matchData['id'] = gamesData[index].id;
                final match = Match.fromJson(matchData);

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
          }
          return Text('snapshot doesn\'t have data :(');
        },
      ),
    );
  }
}
