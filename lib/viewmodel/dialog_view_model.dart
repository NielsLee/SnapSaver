
import 'package:flutter/cupertino.dart';

class DialogViewModel extends ChangeNotifier {

  String _name = "Saver Name";
  String _path = "aaa/bbb/ccc";

  String getName() {
    return _name;
  }

  String getPath() {
    return _path;
  }

  void setName(name) {
    _name = name;
  }

  void setPath(path) {
    _path = path;
  }
}