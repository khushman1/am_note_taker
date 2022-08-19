import 'package:am_note_taker/Models/NoteModel.dart';
import 'package:am_note_taker/Models/Utility.dart';
import 'package:am_note_taker/ViewControllers/HomePage.dart';
import 'package:am_note_taker/Views/ListExpansionTiles.dart';
import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../Models/NoteSetModel.dart';

class NoteSearchDialog extends StatefulWidget {
  final Function(BuildContext, NoteModel) tapCallback;
  final NoteModel? selectedNote;
  final List<NoteModel>? excludeList;

  const NoteSearchDialog(
      {
        required this.tapCallback,
        this.selectedNote,
        this.excludeList,
        Key? key
      }) : super(key: key);

  @override
  _NoteSearchDialogState createState() => _NoteSearchDialogState();
}

class _NoteSearchDialogState extends State<NoteSearchDialog> {
  final GlobalKey _stagKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  String _searchString = "";
  late Function(BuildContext, NoteModel) _noteCallback;

  @override
  Widget build(BuildContext context) {
    _noteCallback = (context, note) {
      Navigator.of(context).pop();
      widget.tapCallback(context, note);
    };
    return getSearchDialog(context, widget.tapCallback);
  }

  Widget getSearchDialog(
      BuildContext context,
      Function(BuildContext, NoteModel) callback) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._dialogHeader(context),
              _dialogListView(context),
            ],
          ),
        ),
      )
    );
  }

  List<Widget> _dialogHeader(BuildContext context) {
    List<Widget> header = List.empty(growable: true);
    late ListExpansionTile parentTile;

    if (widget.selectedNote != null) {
      parentTile = ListExpansionTile(
        note: widget.selectedNote!,
        contentMaxLines: 1,
        titleMaxLines: 2,
      );
    } else {
      NoteModel none = NoteModel.createEmpty();
      none.content = NoteModel.noneNoteEmptyString;
      parentTile = ListExpansionTile(  // empty tile
        note: none,
        contentMaxLines: 1,
        titleMaxLines: 1,
      );
    }

    Widget searchBar = Padding(
      padding: const EdgeInsets.all(4),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
        ),
        decoration: const InputDecoration(
          hintText: "Search note contents",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(),
        ),
        onChanged: (newValue) {
          setState(() {
            _searchString = newValue;
          });
        },
      ),
    );

    header.add(const Text("Current:"));
    header.add(parentTile);
    header.add(searchBar);
    header.add(const Divider());
    return header;
  }
  
  Widget _dialogListView(BuildContext context) {
    return Consumer<NoteSetModel>(builder: (context, noteSetModel, child) {
      Iterable<NoteModel> selectedNotes = noteSetModel.notesList.reversed.where(
        (note) {
          if (widget.excludeList != null) {
            if (widget.excludeList!.contains(note)) {
              return false;
            }
          }
          if (widget.selectedNote == note) {
              // ||
              // (widget.selectedNote != null &&
              //     widget.selectedNote?.parent != null &&
              //     widget.selectedNote?.parent == note)) {
            return false;
          }
          if (_searchString.isEmpty) {
            return true;
          }
          return note.title.contains(_searchString) ||
              note.content.contains(_searchString);
        }
      );
      List<NoteTile> gridViewChildren = selectedNotes.map(
        (note) {
          return CentralStation.generateTile(
              currentNote: note,
              tapCallback: _noteCallback,
              notesViewType: viewType.List
          );
        }
      ).toList();
      // if (widget.selectedNote?.parent != null) {
      //   NoteModel noneNote = CentralStation.createEmptyNoteModel();
      //   noneNote.content = NoteModel.noneNoteEmptyString;
      //   ListExpansionTile noneTile = ListExpansionTile(  // empty tile
      //     note: noneNote,
      //     contentMaxLines: 1,
      //     titleMaxLines: 1,
      //     tapCallback: _noteCallback,
      //   );
      //   gridViewChildren = [noneTile, ...gridViewChildren];
      // }
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width,
        child: StaggeredGridView.count(
          key: _stagKey,
          crossAxisSpacing: 4,
          mainAxisSpacing: 2,
          crossAxisCount: 1,
          children: gridViewChildren,
          staggeredTiles: _tilesForView(gridViewChildren.length),
          physics: const ScrollPhysics(),
        ),
      );
    });
  }

  List<StaggeredTile> _tilesForView(int length) {
    // Generate staggered tiles for the view based on the current preference.
    return List.generate(length, (index) {
      return const StaggeredTile.fit(1);
    });
  }
}