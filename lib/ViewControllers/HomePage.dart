import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'StaggeredGridPage.dart';
import '../Models/Note.dart';
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
        child: _body(),
        right: true,
        left: true,
        top: true,
        bottom: true,
      ),
      bottomSheet: _bottomBar(),
    );
  }

  Widget _body() {
    if (kDebugMode) {
      print(notesViewType);
    }
    return StaggeredGridPage(
      notesViewType: notesViewType,
    );
  }

  Widget _bottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextButton(
          child: const Text(
            "New Note\n",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _newNoteTapped(context),
        )
      ],
    );
  }

  void _newNoteTapped(BuildContext ctx) {
    // "-1" id indicates the note is not new
    var emptyNote =
        Note(-1, "", "", DateTime.now(), DateTime.now(), Colors.white);
    Navigator.push(
        ctx, MaterialPageRoute(builder: (ctx) => NotePage(emptyNote)));
  }

  void _toggleViewType() {
    setState(() {
      CentralStation.updateNeeded = true;
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
