import 'dart:collection';
import 'dart:convert';
import 'package:am_note_taker/Views/ListExpansionTiles.dart';
import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../Models/Note.dart';
import '../Models/SqliteHandler.dart';
import '../Models/Utility.dart';
import '../Views/StaggeredTiles.dart';
import 'HomePage.dart';

class StaggeredGridPage extends StatefulWidget {
  final viewType notesViewType;

  const StaggeredGridPage({Key? key, required this.notesViewType})
      : super(key: key);

  @override
  _StaggeredGridPageState createState() => _StaggeredGridPageState();
}

class _StaggeredGridPageState extends State<StaggeredGridPage> {
  var noteDB = NotesDBHandler();
  late HashSet<Note> _allNotesInQueryResult = HashSet();
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

  void _refreshTriggered() {
    retrieveAllNotesFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey _stagKey = GlobalKey();

    if (kDebugMode) {
      print("update needed?: ${CentralStation.updateNeeded}");
    }
    if (CentralStation.updateNeeded) {
      retrieveAllNotesFromDatabase();
    }
    return Padding(
      padding: _paddingForView(context),
      child: StaggeredGridView.count(
        key: _stagKey,
        crossAxisSpacing: 4,
        mainAxisSpacing: 2,
        crossAxisCount: _colForStaggeredView(context),
        children: List.generate(_allNotesInQueryResult.length, (i) {
          return _tileGenerator(i);
        }),
        staggeredTiles: _tilesForView(),
      ),
    );
  }

  int _colForStaggeredView(BuildContext context) {
    if (widget.notesViewType == viewType.List) {
      return 1;
    }
    // for width larger than 600 on grid mode, return 3 irrelevant of the orientation to accommodate more notes horizontally
    return MediaQuery.of(context).size.width > 600 ? 3 : 2;
  }

  List<StaggeredTile> _tilesForView() {
    // Generate staggered tiles for the view based on the current preference.
    return List.generate(_allNotesInQueryResult.length, (index) {
      return const StaggeredTile.fit(1);
    });
  }

  EdgeInsets _paddingForView(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double padding;
    double topBottom = 8;
    if (width > 500) {
      padding = (width) * 0.05; // 5% padding of width on both side
    } else {
      padding = 8;
    }
    return EdgeInsets.only(
        left: padding, right: padding, top: topBottom, bottom: topBottom);
  }

  NoteTile _tileGenerator(int i) {
    Note currentNote = _allNotesInQueryResult.elementAt(i);
    if (kDebugMode) {
      print("Generating $i tile");
    }

    if (widget.notesViewType == viewType.Staggered) {
      return MyStaggeredTile(currentNote, _refreshTriggered,
          widget.notesViewType != viewType.List);
    } else {
      return ListExpansionTile(currentNote, _refreshTriggered);
    }
  }

  void retrieveAllNotesFromDatabase() {
    if (kDebugMode) {
      print("Retrieving all notes from db.");
    }
    // queries for all the notes from the database ordered by latest edited note. excludes archived notes.
    var _testData = noteDB.selectAllNotes();
    _testData.then((value) {
      if (kDebugMode) {
        int? count = value?.length;
        print("Retrieved $count notes from db.");
      }
      if (value != null) {
        HashSet<Note> noteSet = readDatabaseNotes(value);
        setState(() {
          _allNotesInQueryResult = noteSet;
          CentralStation.updateNeeded = false;
        });
      }
    });
  }

  HashSet<Note> readDatabaseNotes(List<Map<String, dynamic>>? value)
  {
    HashMap<String, Note> noteIdMap = HashMap();
    HashSet<Note> noteSet = HashSet();
    if (value != null) {
      for (var e in value) {
        Note currentNote = convertMapToNote(e);
        noteSet.add(currentNote);
        noteIdMap[currentNote.id] = currentNote;
      }
      if (kDebugMode) {
        print("Values loaded successfully.");
      }

      // Fill in parent and children references
      for (var e in value) {
        Note? currentNote = noteIdMap[e["id"]];
        if (currentNote != null) {
          currentNote.parent = noteIdMap[e["parent"]];
          currentNote.parent?.children.add(currentNote);
        }
      }
      if (kDebugMode) {
        print("Values referenced successfully.");
      }
    }
    return noteSet;
  }

  Note convertMapToNote(Map<String, dynamic> map) {
    return Note(
      map["id"],
      map["title"] == null ? "" : utf8.decode(map["title"]),
      map["content"] == null ? "" : utf8.decode(map["content"]),
      DateTime.fromMillisecondsSinceEpoch(map["date_created"] * 1000),
      DateTime.fromMillisecondsSinceEpoch(map["date_last_edited"] * 1000),
      Color(map["note_color"]),
      null
    );
  }
}
