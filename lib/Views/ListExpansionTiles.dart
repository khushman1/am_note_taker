import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../ViewControllers/NotePage.dart';
import '../Models/Note.dart';
import '../Models/Utility.dart';

class ListExpansionTile extends StatefulWidget implements NoteTile {
  @override
  final Note note;

  @override
  final void Function() refreshTriggeredCallback;

  const ListExpansionTile(this.note, this.refreshTriggeredCallback,
      {Key? key}) : super(key: key);

  @override
  _ListExpansionTileState createState() => _ListExpansionTileState();
}

class _ListExpansionTileState extends State<ListExpansionTile> {
  late String _content;

  late double _fontSize;

  late Color tileColor;

  late String title;

  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    _content = widget.note.content;
    _fontSize = _determineFontSizeForContent();
    tileColor = widget.note.noteColour;
    title = widget.note.title;

    return Card(
      child: constructChild(),
      color: tileColor,
      shadowColor: tileColor,
    );

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

  void _noteTapped(BuildContext ctx) {
    CentralStation.updateNeeded = false;
    Navigator.push(
        ctx, MaterialPageRoute(builder: (ctx) => NotePage(widget.note)))
            .then((value) => _refreshIfNeeded());
  }

  void _refreshIfNeeded() {
    if (CentralStation.updateNeeded) {
      setState(() {});
      widget.refreshTriggeredCallback();
    }
  }

  Widget constructChild() {
    Widget? contentWidget;
    List<Widget> childrenWidgets = [];
    Widget contentInkwell = InkWell(
      splashColor: ColorUtils.invert(widget.note.noteColour).withAlpha(30),
      onTap: () => _noteTapped(context),
      child: AutoSizeText(
        _content,
        style: TextStyle(fontSize: _fontSize),
        maxLines: 2,
        textScaleFactor: 1.5,
        overflow: TextOverflow.ellipsis,
      ),
    );
    Widget titleWidget = contentInkwell;

    if (widget.note.title.isNotEmpty) {
      contentWidget = Padding(
        padding: EdgeInsets.all(4),
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
          textScaleFactor: 1.5,
          overflow: TextOverflow.ellipsis,
      );
      childrenWidgets.add(contentWidget);
      return ExpansionTile(
        title: titleWidget,
        children: childrenWidgets,
        textColor: Colors.black54,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: titleWidget,
    );

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

    contentsOfTiles.add(AutoSizeText(
      _content,
      style: TextStyle(fontSize: _fontSize),
      maxLines: 10,
      textScaleFactor: 1.5,
    ));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: contentsOfTiles);
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
