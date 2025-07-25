import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:snap_saver/db/SaverDatabase.dart';
import 'package:snap_saver/entity/saver.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeViewModel extends ChangeNotifier {
  final List<Saver> _saverList = [];
  double _aspectRatio = 1.0;
  static const String _aspectRatioKey = 'aspect_ratio';
  Color _seedColor = Colors.green;
  int _resolution = 0;
  static const String _resolutionKey = 'resolution';

  HomeViewModel() {
    _initSavers();
    _loadAspectRatio();
    _loadSeedColor();
    _loadResolution();
  }

  List<Saver> get savers => _saverList;
  double get aspectRatio => _aspectRatio;
  Color get seedColor => _seedColor;
  int get resolution => _resolution;

  Future<void> _loadAspectRatio() async {
    final prefs = await SharedPreferences.getInstance();
    _aspectRatio = prefs.getDouble(_aspectRatioKey) ?? 0.5;
    notifyListeners();
  }

  Future<void> updateAspectRatio(double value) async {
    _aspectRatio = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_aspectRatioKey, value);
    notifyListeners();
  }

  Future<void> _loadSeedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('seed_color') ?? Colors.green.value;
    _seedColor = Color(colorValue);
    notifyListeners();
  }

  Future<void> updateSeedColor(Color color) async {
    _seedColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seed_color', color.value);
    notifyListeners();
  }

  Future<void> _loadResolution() async {
    final prefs = await SharedPreferences.getInstance();
    _resolution = prefs.getInt(_resolutionKey) ?? 0;
    notifyListeners();
  }

  Future<void> updateResolution(int value) async {
    if (value < 0 || value > 5) return;
    _resolution = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_resolutionKey, value);
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
