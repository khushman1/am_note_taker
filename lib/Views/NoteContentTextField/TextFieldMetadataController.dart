import 'dart:collection';

import 'package:am_note_taker/Models/NoteModel.dart';
import 'package:am_note_taker/Models/Utility.dart';
import 'package:am_note_taker/Views/NoteContentTextField/ParentReference.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Models/NoteSetModel.dart';

/// [TextFieldMetadataController] is a [TextEditingController] that manages
/// children in between notes. On every [buildTextSpan], the children are
/// re-evaluated. It maintains this list by cloning the set of children on
/// construction, and after, intelligently updates this list to keep track
class TextFieldMetadataController extends TextEditingController {
  static const String startChildTag = "@#@";
  static const String endChildTag = "#@#";
  static const double delimiterFontSize = 14;
  static final Pattern childMatchRegex = RegExp(
      "'$startChildTag([a-zA-Z0-9-]+)'((?:.|\n)*?)'$endChildTag'",
      multiLine: true,
      unicode: true
  );
  final Function(ParentReference) _onHeaderTapFunction;
  final NoteModel _noteBeingEdited;
  late Set<ParentReference> _temporaryChildrenSet;
  
  TextFieldMetadataController(
      this._noteBeingEdited,
      this._onHeaderTapFunction) {
    _temporaryChildrenSet = Set<ParentReference>.from(_noteBeingEdited.children);
  }

  @override
  TextSpan buildTextSpan({
      required BuildContext context,
      TextStyle? style,
      bool? withComposing
  }) {
    HashMap<String, NoteModel> noteMap =
        Provider.of<NoteSetModel>(context, listen: false).noteMap;
    List<InlineSpan> childrenSpans = [];
    // splitMapJoin is a bit tricky here but i found it very handy for
    // populating children list
    text.splitMapJoin(childMatchRegex,
      onMatch: (Match match) {
        ParentReference child = ParentReference.fromMatch(noteMap, match,
            _noteBeingEdited);
        _noteBeingEdited.addChild(newChildRef: child, isBuilding: true);
        _temporaryChildrenSet.remove(child);
        childrenSpans.add(
          TextSpan(
              children: [
                TextSpan(
                  text: "'$startChildTag",
                  style: style?.merge(
                      TextStyle(
                        backgroundColor: Colors.green.withOpacity(0.5),
                        color: Colors.green,
                      )
                  ),
                ),
                TextSpan(
                  text: child.parent.id + "'",
                  style: style?.merge(
                      TextStyle(
                        backgroundColor: Colors.pink.withOpacity(0.5)
                      )
                  ),
                ),
                TextSpan(
                  text: child.content,
                  style: style?.merge(
                      TextStyle(
                          backgroundColor: Colors.orange.withOpacity(0.5)
                      )
                  ),
                ),
                TextSpan(
                  text: "'$endChildTag'",
                  style: style?.merge(
                    TextStyle(
                      backgroundColor: Colors.green.withOpacity(0.5),
                      color: Colors.green,
                      // fontSize: delimiterFontSize,
                    )
                  ),
                ),
              ]
          ),
        );

        return match[0] ?? "";
      },
      onNonMatch: (String text) {
        childrenSpans.add(TextSpan(text: text, style: style));
        return text;
      },
    );
    for (ParentReference child in _temporaryChildrenSet) {
      _noteBeingEdited.removeChild(child: child, isBuilding: true);
    }
    _temporaryChildrenSet = Set<ParentReference>.from(_noteBeingEdited.children);
    return TextSpan(style: style, children: childrenSpans);
  }

  void openWindowOnTap() {
    if (selection.isCollapsed) {
      for (ParentReference reference in _noteBeingEdited.children) {
        if (selection.end >= reference.begin && selection.end < reference.end) {
          int textStart = reference.begin + (startChildTag.length + 1) +
              reference.parent.id.length + 1; // @#@!id!
          if (selection.end < textStart ||
              selection.end > textStart + reference.content.length) {
            if (kDebugMode) {
              print("Within child section header or footer."
                "Selection: ${selection.end}");
            }
            // Allow to change the child here
            _onHeaderTapFunction(reference);
          }
          break;
        }
      }
    }

    if (kDebugMode) {
      print("Selection: ${selection.isCollapsed} ${selection.start}"
          " ${selection.end}");
    }
  }

  /// Replaces an existing child section id with [newChild]'s
  void replaceMatchIDWithNewChildID(ParentReference ref, NoteModel newChild) {
    String beforeID = text.substring(0,
        ref.begin + (startChildTag.length + 1));
    String afterID = text.substring(
        ref.begin + (startChildTag.length + 1) + ref.parent.id.length);
    text = beforeID + newChild.id + afterID;
  }

  /// Returns true if the selection doesn't contain any existing instances. i.e.
  /// it is safe to create a new instance
  bool isSelectionOutOfAllChildren() {
    return !(
        (selection.isCollapsed && isCollapsedSelectionWithinExistingChild()) ||
        (isChildWithinSelectionRange())
    );
  }

  /// Creates a child depending on the text selection
  ///
  /// Takes [newChild] as the NoteModel to add to the new child section.
  ///
  /// Shows the child choice dialog, and if:
  ///   - collapsed on an empty line, or within text, it will create the
  ///     encapsulating format and move the cursor to the content-space in it
  ///   - text is selected, adds the encapsulating format around the selection
  ///   - if the text is empty, add title and content as content
  void createInstanceFromNoteModel(BuildContext context, NoteModel newChild) {
    if (newChild.id == _noteBeingEdited.id) {
      CentralStation.showWarningDialog(
          context: context,
          title: const Text("Error!"),
          content: const Text("Cannot create a child of the same Note."),
      );
      return;
    }
    if (isSelectionOutOfAllChildren()) {
      String middleBlock = text.substring(selection.start, selection.end);
      if (middleBlock.isEmpty) {
        middleBlock = newChild.title + "\n" +
            newChild.content;
      }
      text = text.substring(0, selection.start) +
          "'$startChildTag${newChild.id}'" +
          middleBlock + "'$endChildTag'" +
          text.substring(selection.end);
    }
  }

  /// Clones a [ParentReference] into the current sequence, deleting the current
  /// selection
  void addCloneOfParentReference(BuildContext context, ParentReference ref) {
    if (ref.parent.id == _noteBeingEdited.id) {
      CentralStation.showWarningDialog(
        context: context,
        title: const Text("Error!"),
        content: const Text("Cannot create a child of the same Note."),
      );
      return;
    }
    text = text.substring(0, selection.start) + ref.completeMatch +
        text.substring(selection.end);
  }

  /// Checks if a selected range contains a child section within it
  bool isChildWithinSelectionRange() {
    return _noteBeingEdited.children.any((child) =>
        // Either the selection starts before the child section & ends =after
        (selection.start <= child.begin && selection.end > child.begin)
        // Or it starts after the start of the child section & ends =after
        || (selection.start >= child.begin && selection.start < child.end)
        // Or it is completely within a child
        || (selection.start >= child.begin && selection.end <= child.end)
    );
  }

  /// Checks if a selection is within an existing child section bounds
  bool isCollapsedSelectionWithinExistingChild() {
    return _noteBeingEdited.children.any((child) =>
        selection.end >= child.begin && selection.end < child.end);
  }
}