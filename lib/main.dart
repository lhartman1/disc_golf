import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import './screens/auth_screen.dart';
import './screens/hole_screen.dart';

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
            title: 'Flutter Demo',
            theme: lightTheme,
            darkTheme: darkTheme,
            home: StreamBuilder(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasData) {
                    return HomePage();
                  }
                  return AuthScreen();
                }),
          );
        }

        return CircularProgressIndicator();
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              FirebaseAuth.instance.signOut();
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.exit_to_app),
                    title: Text('Logout'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HoleScreen(title: 'Sam Michael\'s Park'),
              ),
            );
          },
          child: Text('Go to Hole!'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}
