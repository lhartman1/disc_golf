import 'package:counter/screens/hole_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
