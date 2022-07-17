import 'package:am_note_taker/Models/NoteSetModel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'StaggeredGridPage.dart';
import 'NotePage.dart';
import '../Models/Utility.dart';

enum viewType { List, Staggered }

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late viewType notesViewType;

  @override
  void initState() {
    notesViewType = viewType.List;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: _appBarActions(),
        elevation: 1,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Notes"),
      ),
      body: SafeArea(
        child: _body(context),
        right: true,
        left: true,
        top: true,
        bottom: true,
      ),
      bottomSheet: _bottomBar(),
    );
  }

  Widget _body(BuildContext context) {
    if (kDebugMode) {
      print("HomePage body notesViewType: $notesViewType");
    }
    return StaggeredGridPage(
      notesViewType: notesViewType,
      tapCallback: (context, note) => Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => NotePage(note))
      ),
    );
  }

  Widget _bottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextButton(
          child: const Text(
            "➕\tNew Note\n", // symbol is plus
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _newNoteTapped(context),
        )
      ],
    );
  }

  void _newNoteTapped(BuildContext ctx) {
    var emptyNote =
        Provider.of<NoteSetModel>(ctx, listen: false).addEmptyNoteModel();
    Navigator.push(
        ctx, MaterialPageRoute(builder: (ctx) => NotePage(emptyNote)));
  }

  void _toggleViewType() {
    setState(() {
      if (notesViewType == viewType.List) {
        notesViewType = viewType.Staggered;
      } else {
        notesViewType = viewType.List;
      }
    });
  }

  List<Widget> _appBarActions() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          child: GestureDetector(
            onTap: () => _toggleViewType(),
            child: Icon(
              notesViewType == viewType.List
                  ? Icons.developer_board
                  : Icons.view_headline,
              color: CentralStation.fontColor,
            ),
          ),
        ),
      ),
    ];
  }
}
