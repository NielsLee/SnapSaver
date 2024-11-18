import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:snap_saver/db/SaverDatabase.dart';
import 'package:snap_saver/entity/saver.dart';

class HomeViewModel extends ChangeNotifier {
  final List<Saver> _saverList = [];

  HomeViewModel() {
    _initSavers();
  }

  List<Saver> get savers => _saverList;

  int addSaver(Saver newSaver, BuildContext context) {
    if (_saverList.map((e) => e.name).contains(newSaver.name)) {
      return 0;
    }
    _saverList.add(newSaver);
    SaverDatabase().insertSaver(newSaver);
    notifyListeners();
    return 1;
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

  int updateSaver(Saver updatedSaver) {
    final index =
        _saverList.indexWhere((saver) => saver.name == updatedSaver.name);

    if (index != -1) {
      _saverList[index] = updatedSaver;

      SaverDatabase().updateSaver(updatedSaver);
      notifyListeners();
      return 1; // success
    } else {
      return 0;
    }
  }
}
