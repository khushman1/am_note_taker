import 'dart:collection';
import 'dart:convert';

import 'package:am_note_taker/Views/NoteContentTextField/ParentReference.dart';
import 'package:am_note_taker/Views/NoteContentTextField/TextFieldMetadataController.dart';
import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'NoteModel.dart';
import 'NotesDBHandler.dart';

class NoteSetModel extends ChangeNotifier implements NoteListener {
  NotesDBHandler noteDB = NotesDBHandler();
  HashMap<String, NoteModel> _allNotesInQueryResult = HashMap();
  HashMap<String, NoteModel> get noteMap => _allNotesInQueryResult;
  List<NoteModel> get notesList => _allNotesInQueryResult.values.toList();
  List<NoteModel> get conceptsNotesList => _allNotesInQueryResult.values.where(
          (note) => note.children.isEmpty).toList();
  List<NoteModel> get instancesNotesList => _allNotesInQueryResult.values.where(
          (note) => note.children.isNotEmpty).toList();

  NoteSetModel() {
    retrieveNoteSetFromDatabase();
  }

  void _reorderJustModifiedNoteModel(NoteModel note) {
    if (_allNotesInQueryResult.remove(note.id) != null) {
      _allNotesInQueryResult[note.id] = note;
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
    _allNotesInQueryResult.remove(noteToDelete);
    noteDB.deleteNote(noteToDelete).then((value) => notifyListeners());
  }

  NoteModel addEmptyNoteModel() {
    // Note.freshNoteUUID id indicates the note is not new
    var emptyNote = _createNewNoteModel();
    _allNotesInQueryResult[emptyNote.id] = emptyNote;
    notifyListeners();
    return emptyNote;
  }

  NoteModel _createNewNoteModel({
    String title = "",
    String content = "",
    Color noteColor = Colors.white
  }) {
    var newNote = NoteModel.createEmpty();
    newNote.title = title;
    newNote.content = content;
    newNote.noteColour = noteColor;
    noteListener() {
      if (kDebugMode) {
        print("Changed ${newNote.id} ${newNote.title}");
      }
      saveNoteModelToDb(newNote);
      _reorderJustModifiedNoteModel(newNote);
    }
    newNote.removeListener(noteListener);
    newNote.addListener(noteListener);
    return newNote;
  }

  Future<NoteModel> copyNoteModel(NoteModel sourceNote) async {
    NoteModel copy = _createNewNoteModel(
      title: sourceNote.title,
      content: sourceNote.content,
      noteColor: sourceNote.noteColour
    );
    _allNotesInQueryResult[copy.id] = copy;

    await saveNoteModelToDb(copy);
    notifyListeners();
    return copy;
  }

  Future<String> saveNoteModelToDb(NoteModel note) {
    return noteDB.insertNote(note, note.id == NoteModel.freshNoteUUID);
  }

  /// Loads all [NoteModel]s from the database into the [NoteSetModel] and
  /// populates children ids for each [NoteModel]
  HashMap<String, NoteModel> readDatabaseNotes(
      List<Map<String, dynamic>>? value)
  {
    HashMap<String, NoteModel> noteIdMap = HashMap();
    if (value != null) {
      for (var e in value) {
        NoteModel currentNote = convertMapToNote(e);
        noteIdMap[currentNote.id] = currentNote;
      }

      for (NoteModel note in noteIdMap.values) {
        Iterable<Match> matches = TextFieldMetadataController.childMatchRegex
            .allMatches(note.content);
        if (kDebugMode) {
          print("Loading db notes: ${note.title}"
              "${matches.map((e) => e.group(1))}");
        }
        for (Match match in matches) {
          if (match[1] != null && noteIdMap.containsKey(match[1])) {
            note.addChild(newChildRef: ParentReference.fromMatch(noteIdMap,
                match, note, isBuilding: true));
          }
        }
      }
      if (kDebugMode) {
        print("Values referenced successfully.");
      }
    }
    return noteIdMap;
  }

  /// Create [NoteModel] from an individual [NotesDBHandler] row (as a [Map])
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
}