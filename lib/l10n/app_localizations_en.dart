// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SnapSaver';

  @override
  String get howToUse => 'How to use?';

  @override
  String get helpContent =>
      'First, click the button in the lower right corner, enter the path and name to save the photo, and create a photo shooting button; then, click the created button to take a photo and save it to the path corresponding to the button.\nNotice: In some devices, newly created path need a reboot to be recognized by album app.';

  @override
  String get createANewSaver => 'Create a new Saver';

  @override
  String get editSaver => 'Edit Saver';

  @override
  String get delete => 'Delete';

  @override
  String get saverPath => 'Photo save path';

  @override
  String get selectPath => 'Select save path';

  @override
  String get saverName => 'Saver name';

  @override
  String get saverNameDescription => 'Input name of this saver';

  @override
  String get fileName => 'File name';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get preview => 'Preview';

  @override
  String get importAllExistingAlbums => 'Import all existing albums';

  @override
  String get contactDeveloper => 'Contact author';

  @override
  String get browseSourceCode => 'Browse source code';

  @override
  String get notYetImplemented => 'Not yet implemented';

  @override
  String get saverPathExisted => '❌Saver with this path already existed';

  @override
  String get thankForCharlie =>
      '🎉Thanks to Charlie Sierra for the inspiration for this app!';

  @override
  String get removeSaver => 'Remove Saver?';

  @override
  String get name => 'name';

  @override
  String get path => 'path';

  @override
  String get photoName => 'PhotoName';

  @override
  String get photoNameDescription => 'Input photo name';

  @override
  String get more => 'More';

  @override
  String get photoIndex => 'Index';

  @override
  String get photoTimestamp => 'Time';

  @override
  String get photoNameExample => 'PhotoName Example';

  @override
  String get moreDialogFinished => 'PhotoName set successfully';

  @override
  String get buy_me_coffee => 'Buy author a coffee';

  @override
  String get color_scheme => 'Color Scheme';

  @override
  String get resolution_low => 'low';

  @override
  String get resolution_medium => 'medium';

  @override
  String get resolution_high => 'high';

  @override
  String get resolution_vh => 'veryHigh';

  @override
  String get resolution_uh => 'ultraHigh';

  @override
  String get resolution_max => 'max';

  @override
  String get editSaverButton => 'Edit Saver Button';

  @override
  String get openAlbumDirectory => 'Preview Folder';
}
