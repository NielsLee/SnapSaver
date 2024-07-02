import 'package:file_picker/file_picker.dart';

import 'abs_path_picker.dart';

class AndroidNativePathPicker extends PathPicker {

  @override
  void selectPath(void Function(String? p1) callback) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    callback(selectedDirectory);
  }
}