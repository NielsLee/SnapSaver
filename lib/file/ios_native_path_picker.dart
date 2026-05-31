import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'abs_path_picker.dart';

class IOSNativePathPicker extends PathPicker {
  static const MethodChannel _channel = MethodChannel('com.snapsaver/path_picker');

  @override
  void selectPath(void Function(String?) callback) async {
    try {
      final String? path = await _channel.invokeMethod('pickDirectory');
      callback(path);
    } on PlatformException catch (e) {
      debugPrint('Error picking directory: ${e.message}');
      callback(null);
    }
  }

  static Future<String> getAppDocumentsPath() async {
    try {
      final String? path = await _channel.invokeMethod('getAppDocumentsPath');
      return path ?? '';
    } on PlatformException catch (e) {
      debugPrint('Error getting app documents path: ${e.message}');
      return '';
    }
  }
}