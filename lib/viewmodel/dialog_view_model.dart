import 'package:flutter/cupertino.dart';

class DialogViewModel extends ChangeNotifier {
  String _name = "Saver Name";
  List<String> _paths = [];
  Color? _color = null;
  String? _photoName;
  int _suffixType = 0;

  String getName() {
    return _name;
  }

  List<String> getPath() {
    return _paths;
  }

  Color? getColor() {
    return _color;
  }

  String? getPhotoName() {
    return _photoName;
  }

  int getSuffixType() {
    return _suffixType;
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

  void setPhotoName(name) {
    _photoName = name;
  }

  void setSuffixType(type) {
    _suffixType = type;
  }
}
