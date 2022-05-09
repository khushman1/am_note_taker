import 'package:am_note_taker/Models/NoteSetModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Models/NoteModel.dart';
import 'ViewControllers/HomePage.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => NoteSetModel(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AM Noter',
      theme: ThemeData(
        fontFamily: "Roboto",
        iconTheme: const IconThemeData(color: Colors.black),
        primaryTextTheme: const TextTheme(
          headline6: TextStyle(color: Colors.black),
        ),
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}
