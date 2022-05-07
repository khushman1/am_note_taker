import 'package:flutter/material.dart';
import 'ViewControllers/HomePage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AM Noter',
      theme: ThemeData(
        fontFamily: "Roboto",
        iconTheme: IconThemeData(color: Colors.black),
        primaryTextTheme: TextTheme(
          headline6: TextStyle(color: Colors.black),
        ),
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),

    );
  }
}
