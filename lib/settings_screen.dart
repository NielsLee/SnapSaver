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
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Padding(padding: EdgeInsets.fromLTRB(16, 0, 0, 0)),
              Text(AppLocalizations.of(context)!.importAllExistingAlbums, style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    final snackBar = SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.notYetImplemented),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                  icon: const Icon(Icons.photo_album))
            ],
          ),
        ),
        Divider(),
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Padding(padding: EdgeInsets.fromLTRB(16, 0, 0, 0)),
              Text(AppLocalizations.of(context)!.contactDeveloper, style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    _launchMail();
                  },
                  icon: const Icon(Icons.mail))
            ],
          ),
        ),
        Divider(),
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Padding(padding: EdgeInsets.fromLTRB(16, 0, 0, 0)),
              Text(AppLocalizations.of(context)!.browseSourceCode, style: TextStyle(fontWeight: FontWeight.bold)),
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
