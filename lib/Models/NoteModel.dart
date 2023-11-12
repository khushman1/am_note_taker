import 'dart:convert';
import 'package:am_note_taker/Views/NoteContentTextField/ParentReference.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class NoteModel extends ChangeNotifier {
  static const String freshNoteUUID = "__freshnote__";
  static const String noneNoteEmptyString = "<No parent>";
  static const String invalidNoteContent = "____INVALID____";
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

  final Set<ParentReference> _children = {};
  Set<ParentReference> get children => _children;
  void addChild({
    required ParentReference newChildRef
  }) {
    if (_children.contains(newChildRef)) {
      // Removing and readding it resets the other elements in the reference
      _children.remove(newChildRef);
    }
    _children.add(newChildRef);
  }
  void removeChild({
    required ParentReference child
  }) {
    if (_children.remove(child)) {
      child.destroy();
    }
  }

  final Set<ParentReference> _instances = {};
  Set<ParentReference> get instances => _instances;
  void addInstance({
    required ParentReference newInstanceRef,
    bool isBuilding = false
  }) {
    bool notify = true;
    if (_instances.contains(newInstanceRef)) {
      // Removing and readding it resets the other elements in the reference
      _instances.remove(newInstanceRef);
      notify = false; // This makes it not notify
    }
    _instances.add(newInstanceRef);
    if (notify && !isBuilding) {
      notifyListeners();
    }
  }
  void removeInstance({
    required ParentReference instance,
    bool isBuilding = false
  }) {
    if (_instances.remove(instance) && !isBuilding) {
      notifyListeners();
    }
  }

  NoteModel(this.id, this._title, this._content, this.dateCreated,
      this._dateLastEdited, this._noteColour);

  static NoteModel createEmpty()
  {
    return NoteModel(NoteModel.freshNoteUUID, "", "", DateTime.now(),
        DateTime.now(), Colors.white);
  }

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
      'is_archived': isArchived
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
      'is_archived': isArchived
    }.toString();
  }

  bool _isEmptyExceptContent() {
    return (id == NoteModel.freshNoteUUID && _title.isEmpty
        && noteColour == Colors.white && isArchived == 0);
  }

  bool isEmpty() {
    return _isEmptyExceptContent() && _content.isEmpty;
  }

  bool isInvalid() {
    return _isEmptyExceptContent() && _content == invalidNoteContent;
  }

  void markInvalid() {
    _content = invalidNoteContent;
  }
}
