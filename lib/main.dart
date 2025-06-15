import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/dialog/help_dialog.dart';
import 'package:snap_saver/dialog/insert_saver_dialog.dart';
import 'package:snap_saver/settings_screen.dart';
import 'package:snap_saver/viewmodel/dialog_view_model.dart';
import 'package:snap_saver/viewmodel/home_view_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';
import 'entity/saver.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent));
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: context.watch<HomeViewModel>().seedColor,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: context.watch<HomeViewModel>().seedColor,
        ),
      ),
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
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                  Vibration.vibrate(amplitude: 255, duration: 5);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(AppLocalizations.of(context)!.adjust_ratio),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(children: [
                              Icon(Icons.expand),
                              Consumer<HomeViewModel>(
                                builder: (context, viewModel, child) {
                                  return Slider(
                                    value: viewModel.aspectRatio,
                                    min: 0.5,
                                    max: 0.9,
                                    onChanged: (value) async {
                                      await viewModel.updateAspectRatio(value);
                                    },
                                  );
                                },
                              ),
                              Icon(Icons.compress),
                            ]),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: Icon(Icons.aspect_ratio)),
            IconButton(
                onPressed: () {
                  Vibration.vibrate(amplitude: 255, duration: 5);
                  _showHelpDialog();
                },
                icon: Icon(Icons.help_outline)),
            Padding(padding: EdgeInsets.fromLTRB(0, 0, 8, 0))
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
                  color: dialogViewModel.getColor()?.value,
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
                icon: const Icon(Icons.home),
                onPressed: () {
                  Vibration.vibrate(amplitude: 255, duration: 5);
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
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
      pageBuilder: (BuildContext context, anim1, anmi2) {
        return const InsertSaverDialog();
      },
    );
  }

  Future<void> _showHelpDialog() async {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Help Dialog",
      pageBuilder: (BuildContext context, anim1, anmi2) {
        return HelpDialog();
      },
    );
  }
}
