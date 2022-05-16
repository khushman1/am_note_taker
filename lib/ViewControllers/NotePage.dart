import 'package:am_note_taker/ViewControllers/NoteSearchDialog.dart';
import 'package:am_note_taker/Views/NoteTile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../Models/NoteModel.dart';
import '../Models/NoteSetModel.dart';
import 'dart:async';
import '../Models/Utility.dart';
import '../Views/MoreOptionsSheet.dart';
import 'package:share/share.dart';

class NotePage extends StatefulWidget {
  final NoteModel noteInEditing;

  const NotePage(this.noteInEditing, {Key? key}) : super(key: key);

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> implements NoteListener {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late Color noteColor;
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  String _titleFromInitial = "";
  String _contentFromInitial = "";
  late Color _colorFromInitial;
  DateTime _lastEditedForUndo = DateTime.now();

  late NoteModel _editableNote;

  bool _showingBottomSheet = false;
  bool _showingNoteSearchDialog = false;

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

    _persistenceTimer = null;
    if (!_showingNoteSearchDialog && !_showingBottomSheet) {
      _persistenceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        // call insert query here
        if (kDebugMode) {
          print("5 seconds passed");
          print("editable note id: ${_editableNote.id}");
        }
        _persistData();
      });
    }
  }

  @override
  void noteListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editableNote.id == NoteModel.freshNoteUUID && _editableNote.title.isEmpty
        && _editableNote.content.isEmpty
        && !_showingBottomSheet && !_showingNoteSearchDialog) {
      FocusScope.of(context).requestFocus(_titleFocus);
    }
    _editableNote.addListener(noteListener);

    return WillPopScope(
      child: Scaffold(
        key: _globalKey,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: const BackButton(
            color: Colors.black,
          ),
          actions: _notePageActions(context),
          elevation: 1,
          backgroundColor: noteColor,
          title: _pageTitle(),
        ),
        body: _body(context),
      ),
      onWillPop: _readyToPop,
    );
  }

  @override
  void dispose() {
    _persistenceTimer?.cancel();
    _editableNote.removeListener(noteListener);
    super.dispose();
  }

  Widget _body(BuildContext context) {
    var parentController = TextEditingController();
    var messageController = TextEditingController();
    return Container(
        color: noteColor,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              _createParentDisplayField(context, parentController),
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 5),
//          decoration: BoxDecoration(border: Border.all(color: CentralStation.borderColor,width: 1 ),borderRadius: BorderRadius.all(Radius.circular(10)) ),
                  child: TextField(
                    onChanged: (str) => {updateNoteObject()},
                    maxLines: null,
                    controller: _titleController,
                    focusNode: _titleFocus,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                    cursorColor: Colors.blue,
                    decoration: const InputDecoration.collapsed(
                      hintText: "Title",
                      hintStyle: TextStyle(color: Colors.grey)
                    ),
                  ),
                ),
              ),
              const Divider(
                color: CentralStation.borderColor,
              ),
              Flexible(
                  child: Container(
                      padding: const EdgeInsets.all(5),
//    decoration: BoxDecoration(border: Border.all(color: CentralStation.borderColor,width: 1),borderRadius: BorderRadius.all(Radius.circular(10)) ),
                      child: TextField(
                        onChanged: (str) => updateNoteObject(),
                        maxLines: 300,
                        // line limit extendable later
                        controller: _contentController,
                        focusNode: _contentFocus,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 20),
                        cursorColor: Colors.blue,
                        decoration: const InputDecoration.collapsed(
                          hintText: "Note",
                          hintStyle: TextStyle(color: Colors.grey)
                        ),
                      )
                  )
              )
            ],
          ),
          left: true,
          right: true,
          top: false,
          bottom: false,
        ));
  }

  Widget _createParentDisplayField(
      BuildContext context,
      TextEditingController parentController) {
    String parentString = (_editableNote.parent != null)
        ? "${_editableNote.parent?.title}|${_editableNote.parent?.content}"
        : "null";
    parentController.text = "Parent: $parentString";
    return InkWell(
      onTap: () => _showNoteSearchDialog(context),
      child: TextField(
        enabled: false,
        controller: parentController,
        decoration: InputDecoration(
          hintText: "Parent information",
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.blue, width: 5)
          ),
          contentPadding: const EdgeInsets.all(8),
          isCollapsed: true,
          filled: true,
          fillColor: Colors.blueAccent,
        ),
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showNoteSearchDialog(BuildContext context) {
    NoteSetModel noteSet = Provider.of<NoteSetModel>(context, listen: false);
    _showingNoteSearchDialog = true;
    showDialog(
      context: context,
      builder: (ctx) => NoteSearchDialog(
        tapCallback: (ctx, note) {
          if (note.id == NoteModel.freshNoteUUID &&
              note.content == NoteModel.noneNoteEmptyString) {
            noteSet.removeParentFromNoteModel(_editableNote);
          } else {
            noteSet.addParentToNoteModel(_editableNote, note);
          }
          setState(() {});
        },
        showParentForNote: _editableNote
      ),
    ).then((value) => _showingNoteSearchDialog = false);
  }

  Widget _pageTitle() {
    return Text(_editableNote.id == NoteModel.freshNoteUUID ? "New Note" : "Edit Note");
  }

  List<Widget> _notePageActions(BuildContext context) {
    List<Widget> actions = [];
    if (_editableNote.id != NoteModel.freshNoteUUID) {
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
      // Padding(
      //   padding: const EdgeInsets.symmetric(horizontal: 12),
      //   child: InkWell(
      //     child: GestureDetector(
      //       onTap: () => _archivePopup(context),
      //       child: const Icon(
      //         Icons.archive,
      //         color: CentralStation.fontColor,
      //       ),
      //     ),
      //   ),
      // ),
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
    ];
    return actions;
  }

  void bottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext ctx) {
          _showingBottomSheet = true;
          return MoreOptionsSheet(
            color: noteColor,
            callBackColorTapped: _changeColor,
            callBackOptionTapped: bottomSheetOptionTappedHandler,
            dateLastEdited: _editableNote.dateLastEdited,
          );
        }).then((value) => _showingBottomSheet = false);
  }

  void _persistData() {
    updateNoteObject();

    // Provider.of<NoteSetModel>(context, listen: false)
    //     .saveNoteModelToDb(_editableNote);
    // if (_editableNote.id == Note.freshNoteUUID) {
    //   noteDB.insertNote(_editableNote, true);
    //   Future<String> autoIncrementedId =
    //       noteDB.insertNote(_editableNote, true); // for new note
    //   // set the id of the note from the database after inserting the new note so for next persisting
    //   autoIncrementedId.then((value) {
    //     _editableNote.id = value;
    //   });
    // } else {
    //   noteDB.insertNote(
    //       _editableNote, false); // for updating the existing note
    // }
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

      // print("same title? ${_editableNote.title == _titleFromInitial}");
      // print("same content? ${_editableNote.content == _contentFromInitial}");
    }

    // if (!(_editableNote.title == _titleFromInitial &&
    //     _editableNote.content == _contentFromInitial) ||
    //     (_editableNote.id == NoteModel.freshNoteUUID)) {
    //   // No changes to the note
    //   // Change last edit time only if the content of the note is mutated in compare to the note which the page was called with.
    //   _editableNote.dateLastEdited = DateTime.now();
    //   if (kDebugMode) {
    //     print("Updating date_last_edited");
    //   }
    //   CentralStation.updateNeeded = true;
    // }
  }

  void bottomSheetOptionTappedHandler(moreOptions tappedOption) {
    if (kDebugMode) {
      print("option tapped: $tappedOption");
    }
    switch (tappedOption) {
      case moreOptions.delete:
        {
          _deleteNote(_globalKey.currentContext);
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
          _copy(context);
          break;
        }
    }
  }

  void _deleteNote(BuildContext? context) {
    if (context == null) return;
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
                      Navigator.of(context).pop();
                      Provider.of<NoteSetModel>(context, listen: false)
                          .deleteNoteModel(_editableNote);
                      Navigator.of(context).pop();
                    },
                    child: const Text("Yes")),
                TextButton(
                    onPressed: () => {Navigator.of(context).pop()},
                    child: const Text("No")
                )
              ],
            );
          });
  }

  void _changeColor(Color newColorSelected) {
    if (kDebugMode) {
      print("note color changed");
    }
    noteColor = newColorSelected;
    updateNoteObject();
  }

  Future<bool> _readyToPop() async {
    _persistenceTimer?.cancel();
    //show saved toast after calling _persistData function.

    if (_editableNote.title == "" && _editableNote.content == "") {
      Provider.of<NoteSetModel>(context, listen: false)
          .deleteNoteModel(_editableNote);
    } else {
      _persistData();
    }
    return true;
  }

  void _copy(BuildContext context) {
    _persistenceTimer?.cancel();
    Navigator.of(context).pop();
    Provider.of<NoteSetModel>(context, listen: false)
        .copyNoteModel(_editableNote).then((value) {
          Navigator.push(context,
              MaterialPageRoute(builder: (ctx) => NotePage(value)));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Note copied.")));
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
