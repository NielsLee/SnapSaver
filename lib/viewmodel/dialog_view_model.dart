import 'package:flutter/cupertino.dart';

class DialogViewModel extends ChangeNotifier {
  String _name = "Saver Name";
  List<String> _paths = [];
  Color? _color = null;

  String getName() {
    return _name;
  }

  List<String> getPath() {
    return _paths;
  }

  Color? getColor() {
    return _color;
  }

  void setName(name) {
    _name = name;
  }

  void addPath(path) {
    _paths.add(path);
  }

  void setColor(color) {
    _color = color;
  }
}
