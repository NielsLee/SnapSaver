import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IosFileSaveService {
  static const MethodChannel _channel = MethodChannel('com.snapsaver/file_save');

  static Future<String?> saveFile({
    required String sourcePath,
    required String destinationDirectory,
    required String fileName,
  }) async {
    if (destinationDirectory.isEmpty) return null;

    try {
      final result = await _channel.invokeMethod<String>('saveFile', {
        'sourcePath': sourcePath,
        'destinationDirectory': destinationDirectory,
        'fileName': fileName,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to save file via native channel: ${e.message}');
      return null;
    }
  }
}