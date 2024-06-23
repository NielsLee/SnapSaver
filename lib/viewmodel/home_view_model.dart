import 'package:flutter/cupertino.dart';

class HomeViewModel extends ChangeNotifier {
  final List<String> _saverList = [];

  HomeViewModel() {
    _saverList.add("value");
    _saverList.add("dfa");
    _saverList.add("valu23423e");
    _saverList.add("阿斯顿发");
  }

  List<String> get savers => _saverList;

  void addSaver(String name) {
    _saverList.add(name);
    notifyListeners();
  }

  void removeSaver(String name) {
    _saverList.remove(name);
    notifyListeners();
  }
}
