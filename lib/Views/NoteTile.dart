import 'package:flutter/cupertino.dart';

import '../Models/Note.dart';

abstract class NoteTile implements StatefulWidget{
  abstract final Note note;
  abstract final void Function() refreshTriggeredCallback;
}