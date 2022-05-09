import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../ViewControllers/NotePage.dart';
import '../Models/NoteModel.dart';
import '../Models/Utility.dart';

class ListExpansionTile extends StatefulWidget implements NoteTile {
  @override
  final NoteModel note;

  const ListExpansionTile(this.note, {Key? key}) : super(key: key);

  @override
  _ListExpansionTileState createState() => _ListExpansionTileState();
}

class _ListExpansionTileState extends State<ListExpansionTile>
    implements NoteListener {
  late String _content;

  late double _fontSize;

  late Color tileColor;

  late String title;

  bool expanded = false;

  @override
  void noteListener() {
      setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _content = widget.note.content;
    _fontSize = _determineFontSizeForContent();
    tileColor = widget.note.noteColour;
    title = widget.note.title;
    widget.note.addListener(noteListener);

    return Card(
      child: constructChild(),
      color: tileColor,
      shadowColor: tileColor,
    );
  }

  @override
  void dispose() {
    widget.note.removeListener(noteListener);
    super.dispose();

  }

  void _noteOpened(BuildContext ctx) {
    Navigator.push(
        ctx, MaterialPageRoute(builder: (ctx) => NotePage(widget.note)));
  }

  Widget constructChild() {
    Widget? contentWidget;
    List<Widget> childrenWidgets = [];
    Widget contentInkwell = InkWell(
      splashColor: ColorUtils.invert(widget.note.noteColour).withAlpha(30),
      onTap: () => _noteOpened(context),
      child: AutoSizeText(
        _content,
        style: TextStyle(fontSize: _fontSize, color: Colors.black54),
        maxLines: widget.note.title.isEmpty ? 3 : 3,
        textScaleFactor: 1.5,
        overflow: TextOverflow.ellipsis,
      ),
    );
    Widget titleWidget = contentInkwell;

    if (widget.note.title.isNotEmpty) {
      contentWidget = Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: tileColor == Colors.white
                    ? CentralStation.borderColor
                    : ColorUtils.darken(tileColor, 0.3)),
                color: ColorUtils.darken(tileColor, 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(4))),
            child: ListTile(
              title: contentInkwell,
            ),
        ),
      );

      titleWidget = AutoSizeText(
          title,
          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
          maxLines: widget.note.title.isEmpty ? 1 : 3,
          textScaleFactor: 1.6,
          overflow: TextOverflow.ellipsis,
      );
      childrenWidgets.add(contentWidget);
    }
    childrenWidgets.add(_childrenPanel());
    return ExpansionTile(
      title: titleWidget,
      children: childrenWidgets,
      textColor: Colors.black,
    );
  }

  double _determineFontSizeForContent() {
    int charCount = _content.length + widget.note.title.length;
    double fontSize = 20;
    if (charCount > 110) {
      fontSize = 12;
    } else if (charCount > 80) {
      fontSize = 14;
    } else if (charCount > 50) {
      fontSize = 16;
    } else if (charCount > 20) {
      fontSize = 18;
    }

    return fontSize;
  }
}
