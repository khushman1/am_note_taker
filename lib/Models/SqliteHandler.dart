import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'NoteModel.dart';

class NotesDBHandler {
  final databaseName = "notes.db";
  final tableName = "notes";

  final noteEntryMap = {
    "id": "BLOB PRIMARY KEY",
    "title": "BLOB",
    "content": "BLOB",
    "date_created": "INTEGER",
    "date_last_edited": "INTEGER",
    "note_color": "INTEGER",
    "is_archived": "INTEGER",
    "parent": "BLOB"
  };

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) {
      return _database;
    }

    _database = await initDB();
    return _database;
  }

  initDB() async {
    var path = await getDatabasesPath();
    var dbPath = join(path, 'notes.db');
    // ignore: argument_type_not_assignable
    Database dbConnection = await openDatabase(dbPath, version: 1,
        onCreate: (Database db, int version) async {
      if (kDebugMode) {
        print("executing create query from onCreate callback");
      }
      await db.execute(_buildCreateQuery());
    });

    await dbConnection.execute(_buildCreateQuery());
    _buildCreateQuery();
    return dbConnection;
  }

// build the create query dynamically using the column:field dictionary.
  String _buildCreateQuery() {
    String query = "CREATE TABLE IF NOT EXISTS ";
    query += tableName;
    query += "(";
    noteEntryMap.forEach((column, field) {
      if (kDebugMode) {
        print("$column : $field");
      }
      query += "$column $field,";
    });

    query = query.substring(0, query.length - 1);
    query += " )";

    return query;
  }

  static Future<String> dbPath() async {
    String path = await getDatabasesPath();
    return path;
  }

  Future<String> insertNote(NoteModel note, bool isNew) async {
    // Get a reference to the database
    final Database? db = await database;
    if (kDebugMode) {
      print("insert called");
    }

    // Insert the Notes into the correct table.
    await db?.insert('notes', note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // if (isNew) {
    //   // get latest note which isn't archived, limit by 1
    //   var one = await db?.query("notes",
    //       orderBy: "date_last_edited desc",
    //       where: "is_archived = ?",
    //       whereArgs: [0],
    //       limit: 1);
    //   String latestId = one?.first["id"] as String;
    //   return latestId;
    // }
    return note.id;
  }

  Future<bool> copyNote(NoteModel note) async {
    final Database? db = await database;
    try {
      await db?.insert("notes", note.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }
      return false;
    }
    return true;
  }

  Future<bool> archiveNote(NoteModel note) async {
    if (note.id != NoteModel.freshNoteUUID) {
      final Database? db = await database;

      String idToUpdate = note.id;

      db?.update("notes", note.toMap(),
          where: "id = ?", whereArgs: [idToUpdate]);
      return (db != null);
    }
    return false;
  }

  Future<bool> deleteNote(NoteModel note) async {
    if (note.id != NoteModel.freshNoteUUID) {
      final Database? db = await database;
      try {
        await db?.delete("notes", where: "id = ?", whereArgs: [note.id]);
        return true;
      } catch (error) {
        if (kDebugMode) {
          print("Error deleting ${note.id}: ${error.toString()}");
        }
        return false;
      }
    }
    return false;
  }

  Future<List<Map<String, dynamic>>?> selectAllNotes() async {
    final Database? db = await database;
    // query all the notes sorted by last edited
    var data = await db?.query("notes",
        orderBy: "date_last_edited asc",
        where: "is_archived = ?",
        whereArgs: [0]);

    return data;
  }
}
