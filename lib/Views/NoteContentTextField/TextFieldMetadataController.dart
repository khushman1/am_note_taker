import 'package:am_note_taker/Models/NoteModel.dart';
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
      RegExp("'$startChildTag([a-zA-Z0-9-]+)'((?:.|\n)*)'$endChildTag'",
          multiLine: true, unicode: true);

  @override
  TextSpan buildTextSpan({
      required BuildContext context,
      TextStyle? style,
      bool? withComposing
  }) {
    List<InlineSpan> children = [];
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
      print("Match bitch");
        for (int i = 0; i <= match.groupCount; i++)
          {
            print("match ${match.group(i)}");
          }
        print("over");
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
          print("Finally in that shit");
          int textStart = match.start + (startChildTag.length + 1) +
              match.group(1)!.length + 1; // @#@!id!
          if (selection.end < textStart ||
              selection.end > textStart + match.group(2)!.length) {
            print("heading or ending");
            // Allow to change the child here
            _onHeaderTapFunction(match);
          }
          break;
        }
      }
    }

    print("Where cursor ${selection.isCollapsed} ${selection.start} ${selection.end}");
  }

  void replaceMatchIDWithNewChildID(Match match, NoteModel newChild) {
    // replace here
    String beforeID = text.substring(0, match.start + (startChildTag.length + 1));
    String afterID = text.substring(match.start + (startChildTag.length + 1) + match.group(1)!.length);
    print("$beforeID${newChild.id}$afterID");
    text = beforeID + newChild.id + afterID;
  }
}