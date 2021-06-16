import 'package:disc_golf/screens/hole_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

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
    final myTheme = ThemeData(
      // primarySwatch: Colors.lightBlue,
      // primaryColor: Colors.lightBlue[200],
      // accentColor: Colors.amberAccent,
      // scaffoldBackgroundColor: Colors.cyan[50],
      primarySwatch: Colors.orange,
      primaryColor: Color(0xffff7000),
      accentColor: Colors.amberAccent,
      scaffoldBackgroundColor: Colors.orange.shade50,
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
            theme: myTheme,
            darkTheme: myTheme.copyWith(
              brightness: Brightness.dark,
              primaryColor: null,
              scaffoldBackgroundColor: null,
            ),
            home: HomePage(),
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
