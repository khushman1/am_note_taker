import 'dart:collection';

import '../../Models/NoteModel.dart';

/// A reference with a parent NoteModel as found within another NoteModel text.
/// This object is transient on purpose, meant to be created and destroyed as
/// needed. It exists only in memory and is created from [Match]es
class ParentReference {
  late final NoteModel parent;
  late final int begin;
  late final int end;
  late final String content;
  late final String completeMatch;
  late final NoteModel child;

  ParentReference({
    required this.parent,
    required this.begin,
    required this.end,
    required this.content,
    required this.completeMatch,
    required this.child,
    bool isBuilding = false,
  }) {
    parent.addInstance(newInstanceRef: this, isBuilding: isBuilding);
  }

  static ParentReference fromMatch(HashMap<String, NoteModel> noteIdMap,
      Match match, NoteModel child, {isBuilding = false}) {
    String id = match[1] ?? "";
    String content = match[2] ?? "";
    String completeMatch = match[0] ?? "";
    NoteModel? parent = noteIdMap[id];
    return ParentReference(parent: parent!, begin: match.start, end: match.end,
        content: content, completeMatch: completeMatch, child: child,
        isBuilding: isBuilding);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ParentReference
        && parent == other.parent
        && child == other.child;
  }

  void destroy() {
    parent.removeInstance(instance: this, isBuilding: true);
  }
}