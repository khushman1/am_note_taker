import 'package:am_note_taker/Models/NoteModel.dart';
import 'package:am_note_taker/Models/Utility.dart';
import 'package:am_note_taker/ViewControllers/HomePage.dart';
import 'package:am_note_taker/Views/ListExpansionTiles.dart';
import 'package:am_note_taker/Views/NoteContentTextField/ParentReference.dart';
import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../Models/NoteSetModel.dart';

class NoteSearchDialog extends StatefulWidget {
  final Function(BuildContext, NoteModel) tapCallback;
  final NoteModel? selectedNote;
  final List<String>? excludeListIds;
  final bool? searchInstances;
  final Function(BuildContext, ParentReference)? instanceCallback;
  final Function(BuildContext, ParentReference)? childCallback;

  const NoteSearchDialog(
      {
        required this.tapCallback,
        this.selectedNote,
        this.excludeListIds,
        this.searchInstances,
        this.instanceCallback,
        this.childCallback,
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
  late Function(BuildContext, ParentReference) _instanceCallback;
  late Function(BuildContext, ParentReference) _childCallback;

  @override
  Widget build(BuildContext context) {
    _noteCallback = (context, note) {
      Navigator.of(context).pop();
      widget.tapCallback(context, note);
    };
    _instanceCallback = (context, ref) {
      Navigator.of(context).pop();
      if (widget.instanceCallback != null) {
        widget.instanceCallback!(context, ref);
      }
    };
    _childCallback = (context, ref) {
      Navigator.of(context).pop();
      if (widget.childCallback != null) {
        widget.childCallback!(context, ref);
      }
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
    late ListExpansionTile currentChildTile;

    if (widget.selectedNote != null) {
      currentChildTile = ListExpansionTile(
        note: widget.selectedNote!,
        contentMaxLines: 1,
        titleMaxLines: 2,
      );
    } else {
      NoteModel none = NoteModel.createEmpty();
      none.content = NoteModel.noneNoteEmptyString;
      currentChildTile = ListExpansionTile(  // empty tile
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
    header.add(currentChildTile);
    header.add(searchBar);
    header.add(const Divider());
    return header;
  }
  
  Widget _dialogListView(BuildContext context) {
    return Consumer<NoteSetModel>(builder: (context, noteSetModel, child) {
      if (kDebugMode) {
        print("NoteSearchDialog: NoteSetModel consumed");
      }
      List<NoteModel> expandInitially = List.empty(growable: true);
      Iterable<NoteModel> selectedNotes = noteSetModel.notesList.reversed.where(
        (note) {
          if (widget.excludeListIds != null) {
            if (widget.excludeListIds!.contains(note.id)) {
              return false;
            }
          }
          if (widget.selectedNote == note) {
            return false;
          }
          if (_searchString.isEmpty) {
            return true;
          }
          /// We only search within each notes' actual instance
          if (widget.searchInstances != null &&
              widget.searchInstances == true) {
            for (ParentReference ref in note.children) {
              if (ref.content.contains(_searchString)) {
                /// If an instance contains the search term, expand the tile
                expandInitially.add(note);
                return true;
              }
            }
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
              instanceCallback: _instanceCallback,
              childCallback: _childCallback,
              notesViewType: viewType.list,
              initiallyExpanded: expandInitially.contains(note),
          );
        }
      ).toList();
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