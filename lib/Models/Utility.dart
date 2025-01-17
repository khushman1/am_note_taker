import 'package:am_note_taker/Views/NoteContentTextField/ParentReference.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../ViewControllers/HomePage.dart';
import '../Views/ListExpansionTiles.dart';
import '../Views/NoteTile.dart';
import '../Views/StaggeredTiles.dart';
import 'NoteModel.dart';

class CentralStation {
  static const fontColor = Color(0xff595959);
  static const borderColor = Color(0xffd3d3d3);

  static String stringForDatetime(DateTime dt) {
    var dtInLocal = dt.toLocal();
    //DateTime.fromMillisecondsSinceEpoch( 1490489845  * 1000).toLocal(); //year:  1490489845 //>day: 1556152819  //month:  1553561845  //<day: 1556174419
    var now = DateTime.now().toLocal();
    var dateString = "Edited ";

    var diff = now.difference(dtInLocal);

    if (now.day == dtInLocal.day) {
      // creates format like: 12:35 PM,
      var todayFormat = DateFormat("h:mm a");
      dateString += todayFormat.format(dtInLocal);
    } else if ((diff.inDays) == 1 ||
        (diff.inSeconds < 86400 && now.day != dtInLocal.day)) {
      var yesterdayFormat = DateFormat("h:mm a");
      dateString += "Yesterday, " + yesterdayFormat.format(dtInLocal);
    } else if (now.year == dtInLocal.year && diff.inDays > 1) {
      var monthFormat = DateFormat("MMM d");
      dateString += monthFormat.format(dtInLocal);
    } else {
      var yearFormat = DateFormat("MMM d y");
      dateString += yearFormat.format(dtInLocal);
    }

    return dateString;
  }

  static NoteTile generateTile({
    required NoteModel currentNote,
    required viewType notesViewType,
    Function(BuildContext, NoteModel)? tapCallback,
    Function(BuildContext, ParentReference)? instanceCallback,
    Function(BuildContext, ParentReference)? childCallback,
    bool showChildren = true,
    bool initiallyExpanded = false,
  }) {
    if (kDebugMode) {
      print("Generating ${currentNote.id} ${currentNote.title} tile");
    }

    NoteTile returnTile;
    if (notesViewType == viewType.staggered) {
      returnTile = MyStaggeredTile(
        note: currentNote,
        tapCallback: tapCallback,
      );
    } else {
      returnTile = ListExpansionTile(
        note: currentNote,
        tapCallback: tapCallback,
        instanceCallback: instanceCallback,
        childCallback: childCallback,
        showChildren: showChildren,
        initiallyExpanded: initiallyExpanded,
      );
    }

    return ProviderNoteTile(note: currentNote, child: returnTile);
  }

  static void showWarningDialog({
    required BuildContext context,
    required Text title,
    required Text content,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title,
          content: content,
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              }
            ),
          ],
        );
      },
    );
  }
}

class ColorUtils {
  static Color invert(Color color) {
    final r = 255 - color.red;
    final g = 255 - color.green;
    final b = 255 - color.blue;

    return Color.fromARGB((color.opacity * 255).round(), r, g, b);
  }

  static Color darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  static Color lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}

class TextUtils {
  static double determineFontSizeForNoteModel(NoteModel note) {
    return
      determineFontSizeForTextLength(note.title.length + note.content.length);
  }

  static double determineFontSizeForTextLength(int charCount) {
    double fontSize = 20;
    if (charCount > 110) {
      fontSize = 12;
    } else if (charCount > 80) {
      fontSize = 14;
    } else if (charCount > 50) {
      fontSize = 16;
    } else if (charCount > 20) {
      fontSize = 18;
    }

    return fontSize;
  }
}