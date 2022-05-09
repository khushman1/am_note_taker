import 'package:am_note_taker/Views/ListExpansionTiles.dart';
import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../Models/NoteModel.dart';
import '../Models/NoteSetModel.dart';
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
    GlobalKey _stagKey = GlobalKey();

    return Consumer<NoteSetModel>(builder: (context, noteSetModel, child) {
      var gridViewChildren = noteSetModel.notesList.reversed
          .map((e) => _tileGenerator(e)).toList();
      return Padding(
        padding: _paddingForView(context),
        child: StaggeredGridView.count(
          key: _stagKey,
          crossAxisSpacing: 4,
          mainAxisSpacing: 2,
          crossAxisCount: _colForStaggeredView(context),
          children: gridViewChildren,
          staggeredTiles: _tilesForView(noteSetModel.noteSet.length),
        ),
      );
    });
  }

  int _colForStaggeredView(BuildContext context) {
    if (widget.notesViewType == viewType.List) {
      return 1;
    }
    // for width larger than 600 on grid mode, return 3 irrelevant of the orientation to accommodate more notes horizontally
    return MediaQuery.of(context).size.width > 600 ? 3 : 2;
  }

  List<StaggeredTile> _tilesForView(int length) {
    // Generate staggered tiles for the view based on the current preference.
    return List.generate(length, (index) {
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

  NoteTile _tileGenerator(NoteModel currentNote) {
    if (kDebugMode) {
      print("Generating $currentNote tile");
    }

    if (widget.notesViewType == viewType.Staggered) {
      return MyStaggeredTile(currentNote);
    } else {
      return ListExpansionTile(currentNote);
    }
  }
}
