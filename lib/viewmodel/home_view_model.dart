import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:snap_saver/db/SaverDatabase.dart';
import 'package:snap_saver/entity/saver.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeViewModel extends ChangeNotifier {
  final List<Saver> _saverList = [];
  int _resolution = 0;
  int _cameraLensDirection = 0; // 0 = back, 1 = front
  static const String _resolutionKey = 'resolution';
  static const String _cameraLensKey = 'camera_lens_direction';

  HomeViewModel() {
    _initSavers();
    _loadResolution();
    _loadCameraLensDirection();
  }

  List<Saver> get savers => _saverList;
  int get resolution => _resolution;
  int get cameraLensDirection => _cameraLensDirection;

  Future<void> _loadResolution() async {
    final prefs = await SharedPreferences.getInstance();
    _resolution = prefs.getInt(_resolutionKey) ?? 5; // default to max resolution
    notifyListeners();
  }

  Future<void> updateResolution(int value) async {
    if (value < 0 || value > 5) return;
    _resolution = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_resolutionKey, value);
    notifyListeners();
  }

  Future<void> _loadCameraLensDirection() async {
    final prefs = await SharedPreferences.getInstance();
    _cameraLensDirection = prefs.getInt(_cameraLensKey) ?? 0;
    notifyListeners();
  }

  Future<void> updateCameraLensDirection(int value) async {
    if (value < 0 || value > 1) return;
    _cameraLensDirection = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cameraLensKey, value);
    notifyListeners();
  }

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
