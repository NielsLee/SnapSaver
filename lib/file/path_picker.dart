import 'dart:io' show Platform;

import 'abs_path_picker.dart';
import 'android_native_path_picker.dart';
import 'ios_native_path_picker.dart';

PathPicker createPathPicker() {
  if (Platform.isAndroid) {
    return AndroidNativePathPicker();
  } else if (Platform.isIOS) {
    return IOSNativePathPicker();
  }
  throw UnsupportedError('Unsupported platform');
}