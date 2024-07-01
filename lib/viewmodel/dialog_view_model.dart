
import 'package:flutter/cupertino.dart';

class DialogViewModel extends ChangeNotifier {

  String _name = "Saver Name";
  String _path = "aaa/bbb/ccc";
  bool _isSaverCreated = false;

  String getName() {
    return _name;
  }

  String getPath() {
    return _path;
  }

  bool isSaverCreated() {
    return _isSaverCreated;
  }

  void setName(name) {
    _name = name;
  }

  void setPath(path) {
    _path = path;
  }

  void setSaverCreated(isCreated) {
    _isSaverCreated = isCreated;
  }
}