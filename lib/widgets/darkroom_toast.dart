import 'package:fluttertoast/fluttertoast.dart';
import 'package:snap_saver/theme/theme.dart';

class DarkroomToast {
  static void show(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.surface,
      textColor: AppColors.text,
    );
  }
}
