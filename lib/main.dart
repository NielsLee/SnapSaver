import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snap_saver/album_screen.dart';
import 'package:snap_saver/settings_screen.dart';
import 'home_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 设置导航栏透明和边到边
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge).then(
        (_) => runApp(const MainApp()),
  );
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
  // ColorScheme darkScheme = ColorScheme.fromSeed(seedColor: Colors.);


  final List<Widget> _screens = [
    const HomeScreen(),
    const AlbumScreen(),
    const SettingsScreen(),
  ];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      theme: ThemeData(colorScheme: colorScheme),
      darkTheme: ThemeData(colorScheme: colorScheme),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Take a picture'),
          backgroundColor: colorScheme.primaryContainer,
        ),
        body: _screens[_selectedIndex],
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO 添加按钮
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
          )
          ,
        ),
      ),
    );
  }
}
