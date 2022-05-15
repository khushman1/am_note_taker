import 'package:am_note_taker/ViewControllers/NotePage.dart';
import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../Models/NoteModel.dart';
import '../Models/Utility.dart';

class ListExpansionTile extends StatefulWidget implements NoteTile {
  @override
  final NoteModel note;
  final Function(BuildContext, NoteModel)? tapCallback;
  final bool initiallyExpanded;
  final bool showChildren;
  final int contentMaxLines;
  final int titleMaxLines;

  const ListExpansionTile(
      {
        required this.note,
        this.tapCallback,
        this.initiallyExpanded = false,
        this.showChildren = false,
        this.contentMaxLines = 3,
        this.titleMaxLines = 2,
        Key? key,
      }) : super(key: key);

  @override
  _ListExpansionTileState createState() => _ListExpansionTileState();
}

class _ListExpansionTileState extends State<ListExpansionTile>
    implements NoteListener {
  late double _fontSize;

  bool expanded = false;

  @override
  void noteListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _fontSize = _determineFontSizeForContent(widget.note);
    widget.note.addListener(noteListener);

    return Card(
      child: constructChild(
        context,
        widget.note,
        initiallyExpanded: widget.initiallyExpanded,
        showChildren: widget.showChildren
      ),
      color: widget.note.noteColour,
      shadowColor: widget.note.noteColour,
    );
  }

  @override
  void dispose() {
    widget.note.removeListener(noteListener);
    super.dispose();

  }

  void _noteOpened(BuildContext ctx) {
    if (widget.tapCallback != null) {
      widget.tapCallback!(ctx, widget.note);
    }
  }

  Widget constructChild(
      BuildContext context,
      NoteModel note,
      {
        bool initiallyExpanded = false,
        bool showChildren = false,
      }) {
    Widget? contentWidget;
    List<Widget> childrenWidgets = [];
    Widget contentInkwell = InkWell(
      splashColor: ColorUtils.invert(note.noteColour).withAlpha(30),
      onTap: () => _noteOpened(context),
      child: AutoSizeText(
        note.content,
        style: TextStyle(fontSize: _fontSize, color: Colors.black54),
        maxLines: widget.contentMaxLines,
        textScaleFactor: 1.5,
        overflow: TextOverflow.ellipsis,
      ),
    );
    Widget titleWidget = contentInkwell;

    if (note.title.isNotEmpty) {
      contentWidget = Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: note.noteColour == Colors.white
                    ? CentralStation.borderColor
                    : ColorUtils.darken(note.noteColour, 0.3)
                ),
                color: ColorUtils.darken(note.noteColour, 0.1),
                borderRadius: const BorderRadius.all(
                    Radius.circular(4)
                )
            ),
            child: ListTile(
              title: contentInkwell,
            ),
        ),
      );

      titleWidget = InkWell(
          splashColor: ColorUtils.invert(note.noteColour).withAlpha(30),
          onTap: () => _noteOpened(context),
          child: AutoSizeText(
            note.title,
            style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
            maxLines: widget.titleMaxLines,
            textScaleFactor: 1.6,
            overflow: TextOverflow.ellipsis,
          ),
      );
      childrenWidgets.add(contentWidget);
    }
    if (showChildren) {
      childrenWidgets.add(_childrenPanel(context, note));
    }
    if (!showChildren && note.title.isEmpty) {
      // If not showing children and title is empty, remove the tile arrow
      return Padding(
        child: titleWidget,
        padding: const EdgeInsets.all(8),
      );
    }
    return ExpansionTile(
      title: titleWidget,
      children: childrenWidgets,
      textColor: Colors.black,
      initiallyExpanded: initiallyExpanded,
    );
  }

  Widget _childrenPanel(BuildContext context, NoteModel note) {
    return Text(note.children.toString());
  }

  double _determineFontSizeForContent(NoteModel note) {
    int charCount = note.content.length + note.title.length;
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
