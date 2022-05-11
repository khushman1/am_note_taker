import 'package:am_note_taker/Models/NoteModel.dart';
import 'package:am_note_taker/Models/Utility.dart';
import 'package:flutter/material.dart';

class NoteSearchDialog extends StatefulWidget {
  final Function(NoteModel) tapCallback;
  final String dialogTitle;

  const NoteSearchDialog(
      this.tapCallback,
      {
        Key? key,
        this.dialogTitle = "Select Note"
      }) : super(key: key);

  @override
  _NoteSearchDialogState createState() => _NoteSearchDialogState();
}

class _NoteSearchDialogState extends State<NoteSearchDialog> {

  @override
  Widget build(BuildContext context) {
    return getSearchDialog(context, widget.tapCallback, widget.dialogTitle);
  }

  Widget getSearchDialog(
      BuildContext context,
      Function(NoteModel) callback,
      String dialogTitle) {
    return AlertDialog(
      title: Text(dialogTitle),
      insetPadding: const EdgeInsets.all(8),
      content: SingleChildScrollView(
        child: Column(
        // shrinkWrap: true,
        children: [
          TextFormField(
            // controller: parentController,
            decoration: const InputDecoration(hintText: 'Email'),
          ),
          TextFormField(
            // controller: messageController,
            decoration: const InputDecoration(hintText: 'Message'),
          ),
        ])
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Send them to your email maybe?
            // var email = emailController.text;
            // var message = messageController.text;
            Navigator.pop(context);
            var returnNote = CentralStation.createEmptyNoteModel();
            returnNote.title = "Test title";
            callback(returnNote);
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}