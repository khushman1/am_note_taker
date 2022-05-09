import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class NoteModel extends ChangeNotifier {
  static const String freshNoteUUID = "__freshnote__";
  Uuid uuid = const Uuid();

  String id;
  String _title;
  String get title => _title;
  set title(String newTitle) {
    if (newTitle != _title) {
      _title = newTitle;
      dateLastEdited = DateTime.now();
    }
  }

  String _content;
  String get content => _content;
  set content(String newContent) {
    if (newContent != _content) {
      _content = newContent;
      dateLastEdited = DateTime.now();
    }
  }

  DateTime dateCreated;

  DateTime _dateLastEdited;
  DateTime get dateLastEdited => _dateLastEdited;
  set dateLastEdited(DateTime modified) {
    _dateLastEdited = modified;
    notifyListeners();
  }

  Color _noteColour;
  Color get noteColour => _noteColour;
  set noteColour(Color newColor) {
    if (newColor != _noteColour) {
      _noteColour = newColor;
      dateLastEdited = DateTime.now();
    }
  }

  int isArchived = 0;

  NoteModel? _parent;
  NoteModel? get parent => _parent;
  set parent(NoteModel? newParent) {
    if (_parent != newParent) {
      _parent = newParent;
      dateLastEdited = DateTime.now();
    }
  }

  LinkedHashSet<NoteModel> children = LinkedHashSet();

  NoteModel(this.id, this._title, this._content, this.dateCreated,
      this._dateLastEdited, this._noteColour, this._parent);

  Map<String, dynamic> toMap() {
    if (id == freshNoteUUID) {
      id = uuid.v1();
      if (kDebugMode) {
        print("Assigned id $id to $this");
      }
    }
    var data = {
      'id': id,
      'title': utf8.encode(title),
      'content': utf8.encode(content),
      'date_created': epochFromDate(dateCreated),
      'date_last_edited': epochFromDate(dateLastEdited),
      'note_color': noteColour.value,
      'is_archived': isArchived,
      'parent': parent?.id
      //  for later use for integrating archiving
    };
    return data;
  }

// Converting the date time object into int representing seconds passed after midnight 1st Jan, 1970 UTC
  int epochFromDate(DateTime dt) {
    return dt.millisecondsSinceEpoch ~/ 1000;
  }

  void archiveThisNote() {
    isArchived = 1;
  }

// overriding toString() of the note class to print a better debug description of this custom class
  @override
  toString() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date_created': epochFromDate(dateCreated),
      'date_last_edited': epochFromDate(dateLastEdited),
      'note_color': noteColour.toString(),
      'is_archived': isArchived,
      'parent': parent?.id
    }.toString();
  }

  bool isEmpty() {
    return (id == NoteModel.freshNoteUUID && _title.isEmpty && _content.isEmpty
        && noteColour == Colors.white && isArchived == 0 && parent == null);
  }
}
