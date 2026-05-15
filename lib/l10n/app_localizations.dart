import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SnapSaver'**
  String get appTitle;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use?'**
  String get howToUse;

  /// No description provided for @helpContent.
  ///
  /// In en, this message translates to:
  /// **'First, click the button in the lower right corner, enter the path and name to save the photo, and create a photo shooting button; then, click the created button to take a photo and save it to the path corresponding to the button.\nNotice: In some devices, newly created path need a reboot to be recognized by album app.'**
  String get helpContent;

  /// No description provided for @createANewSaver.
  ///
  /// In en, this message translates to:
  /// **'Create a new Saver'**
  String get createANewSaver;

  /// No description provided for @editSaver.
  ///
  /// In en, this message translates to:
  /// **'Edit Saver'**
  String get editSaver;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @saverPath.
  ///
  /// In en, this message translates to:
  /// **'Photo save path'**
  String get saverPath;

  /// No description provided for @selectPath.
  ///
  /// In en, this message translates to:
  /// **'Select save path'**
  String get selectPath;

  /// No description provided for @saverName.
  ///
  /// In en, this message translates to:
  /// **'Saver name'**
  String get saverName;

  /// No description provided for @saverNameDescription.
  ///
  /// In en, this message translates to:
  /// **'Input name of this saver'**
  String get saverNameDescription;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileName;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @importAllExistingAlbums.
  ///
  /// In en, this message translates to:
  /// **'Import all existing albums'**
  String get importAllExistingAlbums;

  /// No description provided for @contactDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Contact author'**
  String get contactDeveloper;

  /// No description provided for @browseSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Browse source code'**
  String get browseSourceCode;

  /// No description provided for @notYetImplemented.
  ///
  /// In en, this message translates to:
  /// **'Not yet implemented'**
  String get notYetImplemented;

  /// No description provided for @saverPathExisted.
  ///
  /// In en, this message translates to:
  /// **'❌Saver with this path already existed'**
  String get saverPathExisted;

  /// No description provided for @thankForCharlie.
  ///
  /// In en, this message translates to:
  /// **'🎉Thanks to Charlie Sierra for the inspiration for this app!'**
  String get thankForCharlie;

  /// No description provided for @removeSaver.
  ///
  /// In en, this message translates to:
  /// **'Remove Saver?'**
  String get removeSaver;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get name;

  /// No description provided for @path.
  ///
  /// In en, this message translates to:
  /// **'path'**
  String get path;

  /// No description provided for @photoName.
  ///
  /// In en, this message translates to:
  /// **'PhotoName'**
  String get photoName;

  /// No description provided for @photoNameDescription.
  ///
  /// In en, this message translates to:
  /// **'Input photo name'**
  String get photoNameDescription;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @photoIndex.
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get photoIndex;

  /// No description provided for @photoTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get photoTimestamp;

  /// No description provided for @photoNameExample.
  ///
  /// In en, this message translates to:
  /// **'PhotoName Example'**
  String get photoNameExample;

  /// No description provided for @moreDialogFinished.
  ///
  /// In en, this message translates to:
  /// **'PhotoName set successfully'**
  String get moreDialogFinished;

  /// No description provided for @buy_me_coffee.
  ///
  /// In en, this message translates to:
  /// **'Buy author a coffee'**
  String get buy_me_coffee;

  /// No description provided for @color_scheme.
  ///
  /// In en, this message translates to:
  /// **'Color Scheme'**
  String get color_scheme;

  /// No description provided for @resolution_low.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get resolution_low;

  /// No description provided for @resolution_medium.
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get resolution_medium;

  /// No description provided for @resolution_high.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get resolution_high;

  /// No description provided for @resolution_vh.
  ///
  /// In en, this message translates to:
  /// **'veryHigh'**
  String get resolution_vh;

  /// No description provided for @resolution_uh.
  ///
  /// In en, this message translates to:
  /// **'ultraHigh'**
  String get resolution_uh;

  /// No description provided for @resolution_max.
  ///
  /// In en, this message translates to:
  /// **'max'**
  String get resolution_max;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
