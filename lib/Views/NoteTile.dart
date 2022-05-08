import 'package:flutter/cupertino.dart';

import '../Models/NoteModel.dart';

abstract class NoteTile implements StatefulWidget{
  abstract final NoteModel note;
  abstract final void Function() refreshTriggeredCallback;
}