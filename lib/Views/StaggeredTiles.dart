import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:provider/provider.dart';
import '../Models/NoteModel.dart';
import '../Models/Utility.dart';

class MyStaggeredTile extends StatefulWidget implements NoteTile {
  @override
  final NoteModel note;
  final bool showContent = true;
  final Function(BuildContext, NoteModel)? tapCallback;

  const MyStaggeredTile(
      {
        required this.note,
        this.tapCallback,
        Key? key
      }) : super(key: key);

  @override
  _MyStaggeredTileState createState() => _MyStaggeredTileState();
}

class _MyStaggeredTileState extends State<MyStaggeredTile> {

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteModel>(
      builder: (_, noteModel, __) {
        double _fontSize = TextUtils.determineFontSizeForNoteModel(noteModel);
        Color tileColor = noteModel.noteColour;
        return GestureDetector(
          onTap: () => _noteTapped(widget.tapCallback, context, noteModel),
          child: Container(
            decoration: BoxDecoration(
                border: tileColor == Colors.white
                    ? Border.all(color: CentralStation.borderColor)
                    : null,
                color: tileColor,
                borderRadius: const BorderRadius.all(Radius.circular(8))),
            padding: const EdgeInsets.all(8),
            child: constructChild(noteModel.content, _fontSize, tileColor,
                noteModel.title, widget.showContent),
          ),
        );
      }
    );
  }

  void _noteTapped(Function(BuildContext, NoteModel)? tapCallback,
      BuildContext ctx, NoteModel note) {
    tapCallback!(ctx, note);
  }

  Widget constructChild(String _content, double _fontSize, Color tileColor,
      String title, bool showContent) {
    List<Widget> contentsOfTiles = [];

    if (title.isNotEmpty) {
      contentsOfTiles.add(
        AutoSizeText(
          title,
          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
          maxLines: title.isEmpty ? 1 : 3,
          textScaleFactor: 1.5,
        ),
      );
      contentsOfTiles.add(
        const Divider(
          color: Colors.transparent,
          height: 6,
        ),
      );
    }

    if (showContent) {
      contentsOfTiles.add(AutoSizeText(
        _content,
        style: TextStyle(fontSize: _fontSize),
        maxLines: 10,
        textScaleFactor: 1.5,
      ));
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: contentsOfTiles);
  }
}
