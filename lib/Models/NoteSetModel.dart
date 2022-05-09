import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'NoteModel.dart';
import 'SqliteHandler.dart';

class NoteSetModel extends ChangeNotifier {
  NotesDBHandler noteDB = NotesDBHandler();
  LinkedHashSet<NoteModel> _allNotesInQueryResult = LinkedHashSet();
  LinkedHashSet<NoteModel> get noteSet => _allNotesInQueryResult;
  List<NoteModel> get notesList => _allNotesInQueryResult.toList();

  NoteSetModel() {
    retrieveNoteSetFromDatabase();
  }

  void sortAllNotesByTimeModified() {
    _allNotesInQueryResult.toList().sort((a, b) => a.dateLastEdited.compareTo(b.dateLastEdited));
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
    noteToDelete.parent?.children.remove(noteToDelete);

    _allNotesInQueryResult.remove(noteToDelete);
    noteDB.deleteNote(noteToDelete).then((value) => notifyListeners());
  }

  NoteModel addEmptyNoteModel() {
    // Note.freshNoteUUID id indicates the note is not new
    var emptyNote = NoteModel(NoteModel.freshNoteUUID, "", "", DateTime.now(),
        DateTime.now(), Colors.white, null);
    _allNotesInQueryResult.add(emptyNote);
    notifyListeners();
    return emptyNote;
  }

  Future<NoteModel> copyNoteModel(NoteModel sourceNote) async {
    NoteModel copy = NoteModel(NoteModel.freshNoteUUID, sourceNote.title,
        sourceNote.content, DateTime.now(), DateTime.now(),
        sourceNote.noteColour, sourceNote.parent);
    _allNotesInQueryResult.add(copy);

    await saveNoteModelToDb(copy);
    notifyListeners();
    return copy;
  }

  Future<String> saveNoteModelToDb(NoteModel note) {
    return noteDB.insertNote(note, note.id == NoteModel.freshNoteUUID)
        .then((value) => note.id = value);
  }

  LinkedHashSet<NoteModel> readDatabaseNotes(List<Map<String, dynamic>>? value)
  {
    HashMap<String, NoteModel> noteIdMap = HashMap();
    LinkedHashSet<NoteModel> noteSet = LinkedHashSet();
    if (value != null) {
      for (var e in value) {
        NoteModel currentNote = convertMapToNote(e);
        noteSet.add(currentNote);
        currentNote.addListener(() {
          saveNoteModelToDb(currentNote);
          sortAllNotesByTimeModified();
        });
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
          currentNote.parent?.children.add(currentNote);
        }
      }
      if (kDebugMode) {
        print("Values referenced successfully.");
      }
    }
    return noteSet;
  }

  NoteModel convertMapToNote(Map<String, dynamic> map) {
    return NoteModel(
        map["id"],
        map["title"] == null ? "" : utf8.decode(map["title"]),
        map["content"] == null ? "" : utf8.decode(map["content"]),
        DateTime.fromMillisecondsSinceEpoch(map["date_created"] * 1000),
        DateTime.fromMillisecondsSinceEpoch(map["date_last_edited"] * 1000),
        Color(map["note_color"]),
        null
    );
  }
}