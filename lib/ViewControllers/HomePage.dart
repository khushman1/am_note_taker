import 'package:am_note_taker/Models/NoteModel.dart';
import 'package:am_note_taker/Models/NoteSetModel.dart';
import 'package:am_note_taker/ViewControllers/ExpandableListPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'StaggeredGridPage.dart';
import 'NotePage.dart';
import '../Models/Utility.dart';

enum viewType { list, staggered }

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late viewType notesViewType;

  @override
  void initState() {
    notesViewType = viewType.list;
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
    if (notesViewType == viewType.staggered) {
      return StaggeredGridPage(
        notesViewType: notesViewType,
        tapCallback: (context, note) => Navigator.push(
            context, _getNotePageRoute(note)
        ),
      );
    }
    return ExpandableListPage(
        notesViewType: notesViewType,
        tapCallback: (context, note) => Navigator.push(
            context, _getNotePageRoute(note)
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

  MaterialPageRoute _getNotePageRoute(NoteModel note) {
    return MaterialPageRoute(builder: (ctx) {
      return ChangeNotifierProvider(create: (_) => note, child: NotePage(note));
    });
  }

  void _newNoteTapped(BuildContext ctx) {
    var emptyNote =
        Provider.of<NoteSetModel>(ctx, listen: false).addEmptyNoteModel();
    Navigator.push(ctx, _getNotePageRoute(emptyNote));
  }

  void _toggleViewType() {
    setState(() {
      if (notesViewType == viewType.list) {
        notesViewType = viewType.staggered;
      } else {
        notesViewType = viewType.list;
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
              notesViewType == viewType.list
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
