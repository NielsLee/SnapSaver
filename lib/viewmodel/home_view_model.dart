import 'package:flutter/cupertino.dart';
import 'package:snap_saver/db/SaverDatabase.dart';
import 'package:snap_saver/entity/saver.dart';

class HomeViewModel extends ChangeNotifier {
  final List<Saver> _saverList = [];

  HomeViewModel() {
    _initSavers();
  }

  List<Saver> get savers => _saverList;

  void addSaver(Saver newSaver) {
    _saverList.add(newSaver);
    SaverDatabase().insertSaver(newSaver);
    notifyListeners();
  }

  void removeSaver(Saver saver) {
    _saverList.remove(saver);
    SaverDatabase().deleteSaver(saver);
    notifyListeners();
  }

  void _initSavers() async {
    final existedSavers = await SaverDatabase().getAllSavers();
    _saverList.addAll(existedSavers);
    notifyListeners();
  }
}
