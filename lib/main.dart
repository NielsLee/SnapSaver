import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/InsertButtonDialog.dart';
import 'package:snap_saver/album_screen.dart';
import 'package:snap_saver/settings_screen.dart';
import 'package:snap_saver/viewmodel/dialog_view_model.dart';
import 'package:snap_saver/viewmodel/home_view_model.dart';
import 'db/SaverDatabase.dart';
import 'entity/saver.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 设置导航栏透明和边到边
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
      ],
      child: const MainApp(),
    ),
  );
  // runApp(const MainApp());
  // SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<StatefulWidget> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: Colors.green);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorScheme: colorScheme),
      darkTheme: ThemeData(colorScheme: colorScheme),
      home: MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<StatefulWidget> createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: Colors.green);

  final List<Widget> _screens = [
    const HomeScreen(),
    const AlbumScreen(),
    const SettingsScreen(),
  ];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SnapSaver'),
          backgroundColor: colorScheme.primaryContainer,
        ),
        body: _screens[_selectedIndex],
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // homeViewModel瑕佷繚璇佸鏋滄甯歌繑鍥炵殑璇濓紝涓€瀹氭槸鏈夊畬鏁寸殑saver淇℃伅鐨?+
            final dialogViewModel = await _showMyDialog();
            if (dialogViewModel != null) {
              final newSaver = Saver(
                  path: dialogViewModel.getPath(),
                  name: dialogViewModel.getName());
              SaverDatabase().insertSaver(newSaver);
              homeViewModel.addSaver(newSaver);
            }
          },
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.photo_album),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<DialogViewModel?> _showMyDialog() async {
    return showGeneralDialog<DialogViewModel>(
      context: context,
      barrierDismissible: false,
      pageBuilder: (BuildContext context, anim1, anmi2) {
        return InsertButtonDialog();
      },
      transitionDuration: const Duration(milliseconds: 150),
      transitionBuilder: (context, anim1, anim2, child) {
        const beginScale = 0.0;
        const endScale = 1.0;
        const beginOpacity = 0.0;
        const endOpacity = 1.0;

        final scale = beginScale + (endScale - beginScale) * anim1.value;
        final opacity =
            beginOpacity + (endOpacity - beginOpacity) * anim1.value;

        final dx = MediaQuery.of(context).size.width * (1 - scale); // Move left
        final dy = MediaQuery.of(context).size.height * (1 - scale); // Move up

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
