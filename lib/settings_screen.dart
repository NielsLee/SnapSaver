import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool isAddButtonShown = true;

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
        Divider()
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
      throw Exception('Could not launch $emailUrl');
    }
  }

  Future<void> _launchGithub() async {
    final Uri githubUrl = Uri(
      scheme: 'https',
      path: 'github.com/NielsLee/SnapSaver',
    );

    if (!await launchUrl(githubUrl)) {
      throw Exception('Could not launch $githubUrl');
    }
  }
}
