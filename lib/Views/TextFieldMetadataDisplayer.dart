import 'package:flutter/cupertino.dart';

class TextFieldMetadataDisplayer extends TextEditingController {
  final String START_CHILD_TAG = "@@@###@@@";
  final String END_CHILD_TAG = "@#@#@#@";
  final Map<String, TextStyle> _mapping;
  final Pattern _pattern;
  
  TextFieldMetadataDisplayer.fromColors(Map<String, Color> colorMap)
      : this(colorMap.map((text, color) =>
      MapEntry(text, TextStyle(color: color))));

  TextFieldMetadataDisplayer(this._mapping) : _pattern =
      RegExp(_mapping.keys.map((key) => RegExp.escape(key)).join('|'));

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
            TextSpan(text: match[0], style: style?.merge(_mapping[match[0]])));
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