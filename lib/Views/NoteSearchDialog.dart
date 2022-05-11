import 'package:am_note_taker/Models/NoteModel.dart';
import 'package:am_note_taker/Models/Utility.dart';
import 'package:flutter/material.dart';

class NoteSearchDialog extends StatefulWidget {
  final Function(NoteModel) callback;

  const NoteSearchDialog(this.callback, {Key? key})
      : super(key: key);

  @override
  _NoteSearchDialogState createState() => _NoteSearchDialogState();
}

class _NoteSearchDialogState extends State<NoteSearchDialog> {

  @override
  Widget build(BuildContext context) {
    return getSearchDialog(context);
  }

  Widget getSearchDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Contact Us'),
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
            widget.callback(returnNote);
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}