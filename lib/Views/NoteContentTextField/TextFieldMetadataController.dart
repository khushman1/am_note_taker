import 'package:am_note_taker/Models/NoteModel.dart';
import 'package:am_note_taker/Models/Utility.dart';
import 'package:am_note_taker/Views/NoteContentTextField/ParentReference.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    List<InlineSpan> childrenSpans = [];
    // splitMapJoin is a bit tricky here but i found it very handy for
    // populating children list
    text.splitMapJoin(childMatchRegex,
      onMatch: (Match match) {
        ParentReference child = ParentReference.fromMatch(match);
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
                  text: child.parentId + "'",
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
              reference.parentId.length + 1; // @#@!id!
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
        ref.begin + (startChildTag.length + 1) + ref.parentId.length);
    text = beforeID + newChild.id + afterID;
  }

  bool isSelectionOutOfAllChildren() {
    return !(
        (selection.isCollapsed && isCollapsedSelectionWithinExistingChild()) ||
        (isChildWithinSelectionRange())
    );
  }

  /// Creates a child depending on the text selection
  ///
  /// Takes [newChild] as the ID to add to the new child section.
  ///
  /// Shows the child choice dialog, and if:
  ///   - collapsed on an empty line, or within text, it will create the
  ///     encapsulating format and move the cursor to the content-space in it
  ///   - text is selected, adds the encapsulating format around the selection
  void createChildFromSelection(BuildContext context, NoteModel newChild) {
    if (selection.isCollapsed) {
      if (isCollapsedSelectionWithinExistingChild()) {
        CentralStation.showWarningDialog(
            context: context,
            title: const Text("Error"),
            content: const Text("Cannot create an instance within an instance.")
        );
      } else {
        text = text.substring(0, selection.end) +
            "'$startChildTag${newChild.id}' '$endChildTag'" +
            text.substring(selection.end);
        // selection = TextSelection.collapsed(offset: selection.end +
        //     (startChildTag.length + 1) + newChild.id.length + 1);
      }
    } else {
      // create child at the beginning and end of selection
      if (isChildWithinSelectionRange()) {
        CentralStation.showWarningDialog(
            context: context,
            title: const Text("Error"),
            content: const Text("Cannot create an instance containing an"
                " instance.")
        );
      } else {
        text = text.substring(0, selection.start) +
            "'$startChildTag${newChild.id}'" +
            text.substring(selection.start, selection.end) + "'$endChildTag'";
      }
    }
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