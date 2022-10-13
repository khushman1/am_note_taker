import 'dart:io';

import 'package:am_note_taker/Models/NotesDBHandler.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class DbBackupManager {
  static const backupDirectory = "storage/emulated/0/am_note_taker/";

  Future<File> dBToCopy() async {
    final String dbPath = await NotesDBHandler.dbPath();
    return File(dbPath + "/notes.db");
  }

  dbExportToBackupFolder() async {
    if (kDebugMode) {
      print("Backing up db at ${DateTime.now()}");
    }
    File result = await dBToCopy();

    Directory copyTo = Directory(backupDirectory);
    if ((await copyTo.exists())) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    } else {
      if (kDebugMode) {
        print("Path doesn't exist");
      }
      if (await Permission.storage.request().isGranted) {
        // Either the permission was already granted before or the user just granted it.
        await copyTo.create();
      } else {
        if (kDebugMode) {
          print('Please give permission');
        }
      }
    }

    String backupDbPath = "${copyTo.path}/am_note_taker.db";
    await result.copy(backupDbPath);
  }
}