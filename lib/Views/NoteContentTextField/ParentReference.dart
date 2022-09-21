/// A reference with a parent NoteModel as found within another NoteModel text.
/// This object is transient on purpose, meant to be created and destroyed as
/// needed. It exists only in memory and is created from [Match]es
class ParentReference {
  late final String parentId;
  late final int begin;
  late final int end;
  late final String content;
  late final String completeMatch;

  ParentReference(this.parentId, this.begin, this.end, this.content,
      this.completeMatch);

  static ParentReference fromMatch(Match match) {
    String id = match[1] ?? "";
    String content = match[2] ?? "";
    String completeMatch = match[0] ?? "";
    return ParentReference(id, match.start, match.end, content, completeMatch);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ParentReference
        && parentId == other.parentId;
  }

  @override
  int get hashCode => parentId.hashCode;
}