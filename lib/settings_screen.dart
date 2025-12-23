import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:snap_saver/viewmodel/home_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool isAddButtonShown = true;
  bool isColorMenuExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Divider(height: 0),
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Padding(padding: EdgeInsets.fromLTRB(16, 0, 0, 0)),
              Text(AppLocalizations.of(context)!.contactDeveloper,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  onPressed: _showThanks, icon: const Icon(Icons.thumb_up)),
              IconButton(onPressed: _launchMail, icon: const Icon(Icons.mail))
            ],
          ),
        ),
        Divider(height: 0),
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Padding(padding: EdgeInsets.fromLTRB(16, 0, 0, 0)),
              Text(AppLocalizations.of(context)!.browseSourceCode,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    _launchGithub();
                  },
                  icon: const ImageIcon(
                    AssetImage('assets/icons/github_mark.png'),
                    size: 24.0,
                  ))
            ],
          ),
        ),
        Divider(height: 0),
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Padding(padding: EdgeInsets.fromLTRB(16, 0, 0, 0)),
              Text(AppLocalizations.of(context)!.buy_me_coffee,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    _launchCoffee();
                  },
                  icon: const Icon(Icons.coffee))
            ],
          ),
        ),
        Divider(height: 0),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Padding(padding: EdgeInsets.fromLTRB(16, 0, 0, 0)),
                  Text(AppLocalizations.of(context)!.color_scheme,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          isColorMenuExpanded = !isColorMenuExpanded;
                        });
                      },
                      icon: Icon(isColorMenuExpanded
                          ? Icons.expand_less
                          : Icons.expand_more))
                ],
              ),
            ),
            if (isColorMenuExpanded)
              Container(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(padding: EdgeInsets.all(8)),
                      _buildColorButton(Colors.red),
                      _buildColorButton(Colors.orange),
                      _buildColorButton(Colors.yellow),
                      _buildColorButton(Colors.green),
                      _buildColorButton(Colors.cyan),
                      _buildColorButton(Colors.blue),
                      _buildColorButton(Colors.purple),
                      Padding(padding: EdgeInsets.all(8)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        Divider(height: 0),
      ],
    );
  }

  void _showThanks() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.thankForCharlie),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchMail() async {
    final Uri emailUrl = Uri(
      scheme: 'mailto',
      path: 'Niels_Lee@outlook.com',
      queryParameters: {
        'subject': 'SnapSaver',
      },
    );

    if (!await launchUrl(emailUrl)) {
      Fluttertoast.showToast(
        msg: '☹️Failed to launch email',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.white,
        textColor: Colors.black,
      );
    }
  }

  Future<void> _launchGithub() async {
    final Uri githubUrl = Uri(
      scheme: 'https',
      path: 'github.com/NielsLee/SnapSaver',
    );

    if (!await launchUrl(githubUrl)) {
      Fluttertoast.showToast(
        msg: '☹️Failed to launch Github',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.white,
        textColor: Colors.black,
      );
    }
  }

  Future<void> _launchCoffee() async {
    final Uri coffeeUrl = Uri(
      scheme: 'https',
      path: 'ko-fi.com/nielslee',
    );

    Fluttertoast.showToast(
      msg: '😊Have a nice day!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.white,
      textColor: Colors.black,
    );

    // await Future.delayed(Duration(milliseconds: 100));

    Fluttertoast.showToast(
      msg: '😊Have a nice day!',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.white,
      textColor: Colors.black,
    );

    await launchUrl(coffeeUrl);
  }

  Widget _buildColorButton(Color color) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        final isSelected = viewModel.seedColor.value == color.value;
        return GestureDetector(
          onTap: () {
            viewModel.updateSeedColor(color);
            Vibration.vibrate(amplitude: 255, duration: 5);
          },
          child: Container(
            width: 48,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
