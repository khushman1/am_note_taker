import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
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

class _MyStaggeredTileState extends State<MyStaggeredTile>
    implements NoteListener {

  late String _content;

  late double _fontSize;

  late Color tileColor;

  late String title;

  @override
  void noteListener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _content = widget.note.content;
    _fontSize = TextUtils.determineFontSizeForNoteModel(widget.note);
    tileColor = widget.note.noteColour;
    title = widget.note.title;
    widget.note.removeListener(noteListener);
    widget.note.addListener(noteListener);

    return GestureDetector(
      onTap: () => _noteTapped(context),
      child: Container(
        decoration: BoxDecoration(
            border: tileColor == Colors.white
                ? Border.all(color: CentralStation.borderColor)
                : null,
            color: tileColor,
            borderRadius: const BorderRadius.all(Radius.circular(8))),
        padding: const EdgeInsets.all(8),
        child: constructChild(),
      ),
    );
  }

  @override
  void dispose() {
    widget.note.removeListener(noteListener);
    super.dispose();
  }

  void _noteTapped(BuildContext ctx) {
    widget.tapCallback!(ctx, widget.note);
  }

  Widget constructChild() {
    List<Widget> contentsOfTiles = [];

    if (widget.note.title.isNotEmpty) {
      contentsOfTiles.add(
        AutoSizeText(
          title,
          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
          maxLines: widget.note.title.isEmpty ? 1 : 3,
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

    if (widget.showContent) {
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
