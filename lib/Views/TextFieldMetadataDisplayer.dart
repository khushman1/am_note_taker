import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TextFieldMetadataDisplayer extends TextEditingController {
  static const String startChildTag = "@#@";
  static const String endChildTag = "#@#";
  final Pattern _pattern;
  
  TextFieldMetadataDisplayer() : _pattern =
      RegExp("$startChildTag([a-zA-Z0-9-]*)\$((.|\n)*)^$endChildTag",
          multiLine: true, unicode: true);

  @override
  TextSpan buildTextSpan({
      required BuildContext context,
      TextStyle? style,
      bool? withComposing
  }) {
    List<InlineSpan> children = [];
    // splitMapJoin is a bit tricky here but i found it very handy for populating children list
    text.splitMapJoin(_pattern,
      onMatch: (Match match) {
        children.add(
          TextSpan(
              text: match[0],
              style: style?.merge(const TextStyle(backgroundColor: Colors.grey))
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
}