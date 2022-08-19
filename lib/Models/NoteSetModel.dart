import 'dart:collection';
import 'dart:convert';

import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'NoteModel.dart';
import 'SqliteHandler.dart';

class NoteSetModel extends ChangeNotifier implements NoteListener {
  NotesDBHandler noteDB = NotesDBHandler();
  LinkedHashSet<NoteModel> _allNotesInQueryResult = LinkedHashSet();
  LinkedHashSet<NoteModel> get noteSet => _allNotesInQueryResult;
  List<NoteModel> get notesList => _allNotesInQueryResult.toList();

  NoteSetModel() {
    retrieveNoteSetFromDatabase();
  }

  void _reorderJustModifiedNoteModel(NoteModel note) {
    if (_allNotesInQueryResult.remove(note)) {
      _allNotesInQueryResult.add(note);
      notifyListeners();
    }
  }

  void retrieveNoteSetFromDatabase() {
    if (kDebugMode) {
      print("Retrieving all notes from db.");
    }
    // queries for all the notes from the database ordered by latest edited note. excludes archived notes.
    var _testData = noteDB.selectAllNotes();
    _testData.then((value) {
      if (kDebugMode) {
        int? count = value?.length;
        print("Retrieved $count notes from db.");
      }
      if (value != null) {
        _allNotesInQueryResult = readDatabaseNotes(value);
        notifyListeners();
      }
    });
  }

  void deleteNoteModel(NoteModel noteToDelete) {
    // Remove tree references before deleting
    for (NoteModel child in noteToDelete.children) {
      child.parent = null;
    }
    noteToDelete.parent?.removeChild(noteToDelete);

    _allNotesInQueryResult.remove(noteToDelete);
    noteDB.deleteNote(noteToDelete).then((value) => notifyListeners());
  }

  NoteModel addEmptyNoteModel() {
    // Note.freshNoteUUID id indicates the note is not new
    var emptyNote = _createNewNoteModel();
    _allNotesInQueryResult.add(emptyNote);
    notifyListeners();
    return emptyNote;
  }

  NoteModel _createNewNoteModel({
    String title = "",
    String content = "",
    Color noteColor = Colors.white,
    NoteModel? parent
  }) {
    var newNote = NoteModel.createEmpty();
    newNote.title = title;
    newNote.content = content;
    newNote.noteColour = noteColor;
    newNote.parent = parent;
    newNote.addListener(() {
      if (kDebugMode) {
        print("Changed ${newNote.title} ${newNote.content}");
      }
      saveNoteModelToDb(newNote);
      _reorderJustModifiedNoteModel(newNote);
    });
    return newNote;
  }

  Future<NoteModel> copyNoteModel(NoteModel sourceNote) async {
    NoteModel copy = _createNewNoteModel(
      title: sourceNote.title,
      content: sourceNote.content,
      noteColor: sourceNote.noteColour,
      parent: sourceNote.parent
    );
    _allNotesInQueryResult.add(copy);

    await saveNoteModelToDb(copy);
    notifyListeners();
    return copy;
  }

  Future<String> saveNoteModelToDb(NoteModel note) {
    return noteDB.insertNote(note, note.id == NoteModel.freshNoteUUID);
  }

  LinkedHashSet<NoteModel> readDatabaseNotes(List<Map<String, dynamic>>? value)
  {
    HashMap<String, NoteModel> noteIdMap = HashMap();
    LinkedHashSet<NoteModel> noteSet = LinkedHashSet();
    if (value != null) {
      for (var e in value) {
        NoteModel currentNote = convertMapToNote(e);
        noteSet.add(currentNote);
        noteIdMap[currentNote.id] = currentNote;
      }
      if (kDebugMode) {
        print("Values loaded successfully. $noteSet");
      }

      // Fill in parent and children references
      for (var e in value) {
        NoteModel? currentNote = noteIdMap[e["id"]];
        if (currentNote != null) {
          currentNote.parent = noteIdMap[e["parent"]];
          currentNote.parent?.addChild(currentNote);
        }
      }
      if (kDebugMode) {
        print("Values referenced successfully.");
      }
    }
    return noteSet;
  }

  NoteModel convertMapToNote(Map<String, dynamic> map) {
    NoteModel note = _createNewNoteModel(
      title: map["title"] == null ? "" : utf8.decode(map["title"]),
      content: map["content"] == null ? "" : utf8.decode(map["content"]),
      noteColor: Color(map["note_color"]),
    );
    note.id = map["id"];
    note.dateCreated =
        DateTime.fromMillisecondsSinceEpoch(map["date_created"] * 1000);
    note.dateLastEdited =
        DateTime.fromMillisecondsSinceEpoch(map["date_last_edited"] * 1000);
    return note;
  }

  @override
  void noteListener() {
    // This is a stub class because this class reads note listeners directly
  }

  void addParentToNoteModel(NoteModel note, NoteModel parent) {
    parent.children.add(note);
    note.parent = parent;
  }

  void removeParentFromNoteModel(NoteModel note) {
    if (note.parent == null) {
      return;
    }
    note.parent!.children.remove(note);
    note.parent = null;
  }
}