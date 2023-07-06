import 'dart:math';

import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../Models/NoteModel.dart';
import '../Models/Utility.dart';
import 'NoteContentTextField/ParentReference.dart';

/// Base component that creates a Tile that is extendable and shows the
/// instances([Children]) of the [NoteModel] alongwith its content.
class ListExpansionTile extends StatefulWidget implements NoteTile {
  @override
  final NoteModel note;
  final Function(BuildContext, NoteModel)? tapCallback;
  final Function(BuildContext, ParentReference)? instanceCallback;
  final Function(BuildContext, ParentReference)? childCallback;
  final bool initiallyExpanded;
  final bool showChildren;
  final int contentMaxLines;
  final int titleMaxLines;

  const ListExpansionTile(
      {
        required this.note,
        this.tapCallback,
        this.instanceCallback,
        this.childCallback,
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
    _fontSize = TextUtils.determineFontSizeForNoteModel(widget.note);
    widget.note.removeListener(noteListener);
    widget.note.addListener(noteListener);

    return Card(
      child: constructChild(
        context: context,
        note: widget.note,
        initiallyExpanded: widget.initiallyExpanded,
        showChildrenNInstances: widget.showChildren
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

  Widget constructChild({
        required BuildContext context,
        required NoteModel note,
        bool initiallyExpanded = false,
        bool showChildrenNInstances = false,
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
    if (showChildrenNInstances) {
      childrenWidgets.add(_childNInstancePanel(context, note));
    }
    if (!showChildrenNInstances && note.title.isEmpty) {
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

  Widget _childNInstancePanel(BuildContext context, NoteModel note) {
    List<Widget> children = [];
    if (note.instances.isNotEmpty) {
      List<Widget> instanceTiles = note.instances.map(
              (e) => _instanceTile(e)).toList();
      children.add(const Text("Instances"));
      children.add(ListView(children: instanceTiles, shrinkWrap: true));
    }
    if (note.children.isNotEmpty) {
      List<Widget> childTiles = note.children.map(
              (e) => _childTile(e)).toList();
      children.add(const Text("Children"));
      children.add(ListView(children: childTiles, shrinkWrap: true));
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _instanceTile(ParentReference ref) {
    return _createdLinkedTile(ref, ref.child, () {
      if (widget.instanceCallback != null && !ref.child.isInvalid()) {
        widget.instanceCallback!(context, ref);
      }
    });
  }

  Widget _childTile(ParentReference ref) {
    return _createdLinkedTile(ref, ref.parent, () {
      if (widget.childCallback != null && !ref.parent.isInvalid()) {
        widget.childCallback!(context, ref);
      }
    });
  }

  Widget _createdLinkedTile(ParentReference ref,
      NoteModel note, Function onTap) {
    if (note.isEmpty()) {
      note.markInvalid();
    }
    int headerLength = 16;
    String noteHeader = note.title.substring(0, min(headerLength, note.title.length));
    if (note.title.length > headerLength) {
      noteHeader += "...";
    }
    if (note.title.isEmpty) {
      noteHeader = note.content.substring(0, min(headerLength, note.content.length));
      if (note.content.length > headerLength) {
        noteHeader += "...";
      }
    }
    String noteSuffix = ref.content.trim().substring(0, min(headerLength, ref.content.trim().length));
    TextStyle headerStyle = TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontSize: TextUtils.determineFontSizeForTextLength(noteHeader.characters.length),
        overflow: TextOverflow.ellipsis
    );
    TextStyle suffixStyle = TextStyle(
        fontWeight: FontWeight.normal,
        color: Colors.black54,
        fontSize: TextUtils.determineFontSizeForTextLength(noteSuffix.characters.length),
        overflow: TextOverflow.ellipsis
    );
    TextStyle arrowStyle = TextStyle(
        fontWeight: FontWeight.normal,
        color: Colors.grey,
        fontSize: TextUtils.determineFontSizeForTextLength(noteSuffix.characters.length),
        overflow: TextOverflow.ellipsis
    );
    return Card(
      child: InkWell(
        onTap: () => onTap(),
        splashColor: ColorUtils.invert(note.noteColour).withAlpha(30),
        child: ListTile(
          title: RichText(
            text: TextSpan(children: [
              TextSpan(text: noteHeader, style: headerStyle),
              TextSpan(text: ' > ', style: arrowStyle),
              TextSpan(text: noteSuffix, style: suffixStyle),
            ]),
          ),
        ),
      ),
      color: ColorUtils.darken(note.noteColour),
      shadowColor: ColorUtils.darken(note.noteColour),
    );
  }
}
