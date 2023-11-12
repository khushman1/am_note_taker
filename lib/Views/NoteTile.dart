import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Models/NoteModel.dart';

abstract class NoteTile implements Widget {
  abstract final NoteModel note;
}

class ProviderNoteTile extends StatelessWidget implements NoteTile {
  @override
  final NoteModel note;
  final Widget child;

  const ProviderNoteTile({
    required this.note,
    required this.child,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NoteModel>(
      create: (_) => note,
      child: child,
    );
  }
}

abstract class NoteListener {
  void noteListener();
}