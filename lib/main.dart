import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/dialog/help_dialog.dart';
import 'package:snap_saver/dialog/insert_saver_dialog.dart';
import 'package:snap_saver/settings_screen.dart';
import 'package:snap_saver/theme/theme.dart';
import 'package:snap_saver/viewmodel/dialog_view_model.dart';
import 'package:snap_saver/viewmodel/home_view_model.dart';
import 'package:snap_saver/l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';
import 'entity/saver.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Only support protrait layout now
  // TODO: support landscape layout
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<StatefulWidget> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.buildTheme(),
      themeMode: ThemeMode.dark,
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<StatefulWidget> createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const SettingsScreen(),
  ];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.appTitle),
          actions: [
            IconButton(
                onPressed: () {
                  Vibration.vibrate(amplitude: 255, duration: 5);
                  _showHelpDialog();
                },
                icon: const Icon(Icons.help_outline, color: AppColors.muted)),
            const Padding(padding: EdgeInsets.fromLTRB(0, 0, 8, 0))
          ],
        ),
        body: _screens[_selectedIndex],
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final dialogViewModel = await _showInsertDialog();
            if (dialogViewModel != null) {
              final newSaver = Saver(
                  paths: dialogViewModel.getPath(),
                  name: dialogViewModel.getName(),
                  color: dialogViewModel.getColor()?.toARGB32(),
                  photoName: dialogViewModel.getPhotoName(),
                  suffixType: dialogViewModel.getSuffixType());

              int res = homeViewModel.addSaver(newSaver, context);
              if (res == 0) {
                final snackBar = SnackBar(
                  content: Text(AppLocalizations.of(context)!.saverPathExisted),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            }
          },
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.home,
                    color: _selectedIndex == 0
                        ? AppColors.accent
                        : AppColors.muted),
                onPressed: () {
                  Vibration.vibrate(amplitude: 255, duration: 5);
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.settings,
                    color: _selectedIndex == 1
                        ? AppColors.accent
                        : AppColors.muted),
                onPressed: () {
                  Vibration.vibrate(amplitude: 255, duration: 5);
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<DialogViewModel?> _showInsertDialog() async {
    Vibration.vibrate(amplitude: 255, duration: 5);
    return showGeneralDialog<DialogViewModel>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.background.withValues(alpha: 0.7),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
      pageBuilder: (BuildContext context, anim1, anim2) {
        return const InsertSaverDialog();
      },
    );
  }

  Future<void> _showHelpDialog() async {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.background.withValues(alpha: 0.7),
      barrierLabel: "Help Dialog",
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
      pageBuilder: (BuildContext context, anim1, anim2) {
        return HelpDialog();
      },
    );
  }
}
