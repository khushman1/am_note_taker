import 'package:am_note_taker/Models/Utility.dart';
import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/NoteModel.dart';
import '../Models/NoteSetModel.dart';
import 'HomePage.dart';

class ExpandableListPage extends StatefulWidget {
  final viewType notesViewType;
  final Function(BuildContext, NoteModel)? tapCallback;

  const ExpandableListPage({
    Key? key,
    required this.notesViewType,
    this.tapCallback
  }) : super(key: key);

  @override
  _ExpandableListPageState createState() => _ExpandableListPageState();
}

class _ExpandableListPageState extends State<ExpandableListPage> {
  late viewType notesViewType;

  @override
  void initState() {
    super.initState();
    notesViewType = widget.notesViewType;
  }

  @override
  void setState(fn) {
    super.setState(fn);
    notesViewType = widget.notesViewType;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteSetModel>(builder: (context, noteSetModel, child) {
      if (kDebugMode) {
        print("ExpandableListPage: NoteSetModel consumed");
      }
      List<NoteTile> conceptsChildren = noteSetModel.conceptsNotesList.reversed
          .map((note) {
        return CentralStation.generateTile(
            currentNote: note,
            notesViewType: widget.notesViewType,
            tapCallback: widget.tapCallback,
            instanceCallback: (ctx, ref) =>
                widget.tapCallback!(ctx, ref.child),
            childCallback: (ctx, ref) => widget.tapCallback!(ctx, ref.parent),
            showChildren: true
        );
      }).toList();
      List<NoteTile> instancesChildren = noteSetModel.instancesNotesList.
          reversed.map((note) {
        return CentralStation.generateTile(
            currentNote: note,
            notesViewType: widget.notesViewType,
            tapCallback: widget.tapCallback,
            instanceCallback: (ctx, ref) =>
                widget.tapCallback!(ctx, ref.child),
            childCallback: (ctx, ref) => widget.tapCallback!(ctx, ref.parent),
            showChildren: true
        );
      }).toList();

      return ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          ExpansionTile(
              title: const Text("Concepts"),
              children: conceptsChildren,
          ),
          ExpansionTile(
            title: const Text("Instances"),
            children: instancesChildren,
          ),
        ],
      );
    });
  }
}
