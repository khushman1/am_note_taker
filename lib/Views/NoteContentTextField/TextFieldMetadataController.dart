import 'package:am_note_taker/Models/NoteModel.dart';
import 'package:am_note_taker/Models/Utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TextFieldMetadataController extends TextEditingController {
  static const String startChildTag = "@#@";
  static const String endChildTag = "#@#";
  static const double delimiterFontSize = 14;
  List<Match> matchList = List.empty(growable: true);
  final Pattern _pattern;
  final Function(Match)  _onHeaderTapFunction;
  
  TextFieldMetadataController(this._onHeaderTapFunction) : _pattern =
      RegExp("'$startChildTag([a-zA-Z0-9-]+)'((?:.|\n)*?)'$endChildTag'",
          multiLine: true, unicode: true);

  @override
  TextSpan buildTextSpan({
      required BuildContext context,
      TextStyle? style,
      bool? withComposing
  }) {
    List<InlineSpan> children = [];
    matchList.clear();
    // matchList = _pattern.allMatches(text).toList();
    // if (kDebugMode) {
    //   print("Rachel Sonia Cox $matchList");
    //   matchList.forEach((item){
    //     print("${item.start} ${item.end} ${item.group(0)}");
    //   });
    // }
    // splitMapJoin is a bit tricky here but i found it very handy for populating children list
    text.splitMapJoin(_pattern,
      onMatch: (Match match) {
      // print("Match bitch");
      //   for (int i = 0; i <= match.groupCount; i++)
      //     {
      //       print("match ${match.group(i)}");
      //     }
      //   print("over");
        matchList.add(match);
        children.add(
          TextSpan(
              children: [
                TextSpan(
                  text: "'$startChildTag",
                  style: style?.merge(
                      TextStyle(
                        backgroundColor: Colors.green.withOpacity(0.5),
                        color: Colors.green,
                        // fontSize: delimiterFontSize,
                      )
                  ),
                ),
                // WidgetSpan(child: Text(
                //   // controller: TextEditingController(text: match[1]),
                //   match[1] ?? "",
                //   style: style?.merge(TextStyle(backgroundColor: Colors.pink.withOpacity(0.5))),
                // )),
                TextSpan(
                  text: (match[1] ?? "") + "'",
                  style: style?.merge(TextStyle(backgroundColor: Colors.pink.withOpacity(0.5))),
                ),
                TextSpan(
                  text: match[2],
                  style: style?.merge(TextStyle(backgroundColor: Colors.orange.withOpacity(0.5))),
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
        return "";
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: style));
        return "";
      },
    );
    return TextSpan(style: style, children: children);
  }

  void _showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('AlertDialog Title'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('This is a demo alert dialog.'),
                Text('Would you like to approve of this message?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void openWindowOnTap() {
    if (selection.isCollapsed) {
      for (Match match in matchList) {
        if (selection.end >= match.start && selection.end < match.end) {
          int textStart = match.start + (startChildTag.length + 1) +
              match.group(1)!.length + 1; // @#@!id!
          if (selection.end < textStart ||
              selection.end > textStart + match.group(2)!.length) {
            if (kDebugMode) {
              print("Within child section header or footer."
                "Selection: ${selection.end}");
            }
            // Allow to change the child here
            _onHeaderTapFunction(match);
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
  void replaceMatchIDWithNewChildID(Match match, NoteModel newChild) {
    // replace here
    String beforeID = text.substring(0, match.start + (startChildTag.length + 1));
    String afterID = text.substring(match.start + (startChildTag.length + 1) + match.group(1)!.length);
    text = beforeID + newChild.id + afterID;
  }

  /// Creates a child depending on the text selection
  ///
  /// Takes [newChild] as the ID to add to the new child section.
  ///
  /// Shows the child choice dialog, and if:
  ///   - collapsed on an empty line, or within text, it will create the
  ///     encapsulating format and move the cursor to the content-space in it
  ///   - text is selected, adds the encapsulating format around the selection
  void createChild(BuildContext context, NoteModel newChild) {
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
    return matchList.any((child) =>
        // Either the selection starts before the child section & ends =after
        (selection.start <= child.start && selection.end > child.start)
        // Or it starts after the start of the child section & ends =after
        || (selection.start >= child.start && selection.start < child.end)
        // Or it is completely within a child
        || (selection.start >= child.start && selection.end <= child.end)
    );
  }

  /// Checks if a selection is within an existing child section bounds
  bool isCollapsedSelectionWithinExistingChild() {
    return matchList.any((child) =>
        selection.end >= child.start && selection.end < child.end);
  }
}