import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Models/Note.dart';
import '../Models/SqliteHandler.dart';
import 'dart:async';
import '../Models/Utility.dart';
import '../Views/MoreOptionsSheet.dart';
import 'package:share/share.dart';

class NotePage extends StatefulWidget {
  final Note noteInEditing;

  const NotePage(this.noteInEditing);

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late Color noteColor;
  bool _isNewNote = false;
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  String _titleFromInitial = "";
  String _contentFromInitial = "";
  late Color _colorFromInitial;
  DateTime _lastEditedForUndo = DateTime.now();

  late Note _editableNote;

  // the timer variable responsible to call persistData function every 5 seconds and cancel the timer when the page pops.
  Timer? _persistenceTimer;

  final GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _editableNote = widget.noteInEditing;
    _titleController.text = _editableNote.title;
    _contentController.text = _editableNote.content;
    noteColor = _editableNote.noteColour;
    _lastEditedForUndo = widget.noteInEditing.dateLastEdited;

    _titleFromInitial = widget.noteInEditing.title;
    _contentFromInitial = widget.noteInEditing.content;
    _colorFromInitial = widget.noteInEditing.noteColour;

    if (widget.noteInEditing.id == -1) {
      _isNewNote = true;
    }
    _persistenceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // call insert query here
      if (kDebugMode) {
        print("5 seconds passed");
        print("editable note id: ${_editableNote.id}");
      }
      _persistData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_editableNote.id == -1 && _editableNote.title.isEmpty) {
      FocusScope.of(context).requestFocus(_titleFocus);
    }

    return WillPopScope(
      child: Scaffold(
        key: _globalKey,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: const BackButton(
            color: Colors.black,
          ),
          actions: _archiveAction(context),
          elevation: 1,
          backgroundColor: noteColor,
          title: _pageTitle(),
        ),
        body: _body(context),
      ),
      onWillPop: _readyToPop,
    );
  }

  Widget _body(BuildContext ctx) {
    return Container(
        color: noteColor,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(5),
//          decoration: BoxDecoration(border: Border.all(color: CentralStation.borderColor,width: 1 ),borderRadius: BorderRadius.all(Radius.circular(10)) ),
                  child: EditableText(
                      onChanged: (str) => {updateNoteObject()},
                      maxLines: null,
                      controller: _titleController,
                      focusNode: _titleFocus,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                      cursorColor: Colors.blue,
                      backgroundCursorColor: Colors.blue),
                ),
              ),
              const Divider(
                color: CentralStation.borderColor,
              ),
              Flexible(
                  child: Container(
                      padding: const EdgeInsets.all(5),
//    decoration: BoxDecoration(border: Border.all(color: CentralStation.borderColor,width: 1),borderRadius: BorderRadius.all(Radius.circular(10)) ),
                      child: EditableText(
                        onChanged: (str) => {updateNoteObject()},
                        maxLines: 300,
                        // line limit extendable later
                        controller: _contentController,
                        focusNode: _contentFocus,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 20),
                        backgroundCursorColor: Colors.red,
                        cursorColor: Colors.blue,
                      )))
            ],
          ),
          left: true,
          right: true,
          top: false,
          bottom: false,
        ));
  }

  Widget _pageTitle() {
    return Text(_editableNote.id == -1 ? "New Note" : "Edit Note");
  }

  List<Widget> _archiveAction(BuildContext context) {
    List<Widget> actions = [];
    if (widget.noteInEditing.id != -1) {
      actions.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          child: GestureDetector(
            onTap: () => _undo(),
            child: const Icon(
              Icons.undo,
              color: CentralStation.fontColor,
            ),
          ),
        ),
      ));
    }
    actions += [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          child: GestureDetector(
            onTap: () => _archivePopup(context),
            child: const Icon(
              Icons.archive,
              color: CentralStation.fontColor,
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          child: GestureDetector(
            onTap: () => bottomSheet(context),
            child: const Icon(
              Icons.more_vert,
              color: CentralStation.fontColor,
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          child: GestureDetector(
            onTap: () => {_saveAndStartNewNote(context)},
            child: const Icon(
              Icons.add,
              color: CentralStation.fontColor,
            ),
          ),
        ),
      )
    ];
    return actions;
  }

  void bottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext ctx) {
          return MoreOptionsSheet(
            color: noteColor,
            callBackColorTapped: _changeColor,
            callBackOptionTapped: bottomSheetOptionTappedHandler,
            dateLastEdited: _editableNote.dateLastEdited,
          );
        });
  }

  void _persistData() {
    updateNoteObject();

    var noteDB = NotesDBHandler();

    if (_editableNote.id == -1) {
      Future<int> autoIncrementedId =
          noteDB.insertNote(_editableNote, true); // for new note
      // set the id of the note from the database after inserting the new note so for next persisting
      autoIncrementedId.then((value) {
        _editableNote.id = value;
      });
    } else {
      noteDB.insertNote(
          _editableNote, false); // for updating the existing note
    }
  }

// this function will ne used to save the updated editing value of the note to the local variables as user types
  void updateNoteObject() {
    _editableNote.content = _contentController.text;
    _editableNote.title = _titleController.text;
    _editableNote.noteColour = noteColor;
    if (kDebugMode) {
      print("new content: ${_editableNote.content}");
      print(widget.noteInEditing);
      print(_editableNote);

      print("same title? ${_editableNote.title == _titleFromInitial}");
      print("same content? ${_editableNote.content == _contentFromInitial}");
    }

    if (!(_editableNote.title == _titleFromInitial &&
        _editableNote.content == _contentFromInitial) ||
        (_isNewNote)) {
      // No changes to the note
      // Change last edit time only if the content of the note is mutated in compare to the note which the page was called with.
      _editableNote.dateLastEdited = DateTime.now();
      if (kDebugMode) {
        print("Updating date_last_edited");
      }
      CentralStation.updateNeeded = true;
    }
  }

  void bottomSheetOptionTappedHandler(moreOptions tappedOption) {
    if (kDebugMode) {
      print("option tapped: $tappedOption");
    }
    switch (tappedOption) {
      case moreOptions.delete:
        {
          if (_editableNote.id != -1) {
            _deleteNote(_globalKey.currentContext);
          } else {
            _exitWithoutSaving(context);
          }
          break;
        }
      case moreOptions.share:
        {
          if (_editableNote.content.isNotEmpty) {
            Share.share("${_editableNote.title}\n${_editableNote.content}");
          }
          break;
        }
      case moreOptions.copy:
        {
          _copy();
          break;
        }
    }
  }

  void _deleteNote(BuildContext? context) {
    if (context == null) return;
    if (_editableNote.id != -1) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm ?"),
              content: const Text("This note will be deleted permanently"),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      _persistenceTimer?.cancel();
                      var noteDB = NotesDBHandler();
                      Navigator.of(context).pop();
                      noteDB.deleteNote(_editableNote);
                      CentralStation.updateNeeded = true;

                      Navigator.of(context).pop();
                    },
                    child: const Text("Yes")),
                TextButton(
                    onPressed: () => {Navigator.of(context).pop()},
                    child: const Text("No"))
              ],
            );
          });
    }
  }

  void _changeColor(Color newColorSelected) {
    if (kDebugMode) {
      print("note color changed");
    }
    setState(() {
      noteColor = newColorSelected;
      _editableNote.noteColour = newColorSelected;
    });
    updateNoteObject();
    _persistColorChange();
    CentralStation.updateNeeded = true;
  }

  void _persistColorChange() {
    if (_editableNote.id != -1) {
      var noteDB = NotesDBHandler();
      _editableNote.noteColour = noteColor;
      noteDB.insertNote(_editableNote, false);
    }
  }

  void _saveAndStartNewNote(BuildContext context) {
    _persistenceTimer?.cancel();
    var emptyNote =
        Note(-1, "", "", DateTime.now(), DateTime.now(), Colors.white);
    Navigator.of(context).pop();
    Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => NotePage(emptyNote)));
  }

  Future<bool> _readyToPop() async {
    _persistenceTimer?.cancel();
    //show saved toast after calling _persistData function.

    _persistData();
    return true;
  }

  void _archivePopup(BuildContext context) {
    if (_editableNote.id != -1) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm ?"),
              content: const Text("This note will be archived"),
              actions: <Widget>[
                TextButton(
                    onPressed: () => _archiveThisNote(context),
                    child: const Text("Yes")),
                TextButton(
                    onPressed: () => {Navigator.of(context).pop()},
                    child: const Text("No"))
              ],
            );
          });
    } else {
      _exitWithoutSaving(context);
    }
  }

  void _exitWithoutSaving(BuildContext context) {
    _persistenceTimer?.cancel();
    CentralStation.updateNeeded = false;
    Navigator.of(context).pop();
  }

  void _archiveThisNote(BuildContext context) {
    Navigator.of(context).pop();
    // set archived flag to true and send the entire note object in the database to be updated
    _editableNote.isArchived = 1;
    var noteDB = NotesDBHandler();
    noteDB.archiveNote(_editableNote);
    // update will be required to remove the archived note from the staggered view
    CentralStation.updateNeeded = true;
    _persistenceTimer?.cancel(); // shutdown the timer

    Navigator.of(context).pop(); // pop back to staggered view
    // TODO: OPTIONAL show the toast of deletion completion

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("deleted")));
  }

  void _copy() {
    var noteDB = NotesDBHandler();
    Note copy = Note(-1, _editableNote.title, _editableNote.content,
        DateTime.now(), DateTime.now(), _editableNote.noteColour);

    var status = noteDB.copyNote(copy);
    status.then((querySuccess) {
      if (querySuccess) {
        CentralStation.updateNeeded = true;
        Navigator.of(_globalKey.currentContext!).pop();
      }
    });
  }

  void _undo() {
    _titleController.text = _titleFromInitial; // widget.noteInEditing.title;
    _contentController.text =
        _contentFromInitial; // widget.noteInEditing.content;
    _editableNote.dateLastEdited =
        _lastEditedForUndo; // widget.noteInEditing.date_last_edited;
    _editableNote.noteColour =
        _colorFromInitial; // widget.noteInEditing.note_color
  }
}
