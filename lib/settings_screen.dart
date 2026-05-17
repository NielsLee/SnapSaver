import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:snap_saver/l10n/app_localizations.dart';
import 'package:snap_saver/theme/theme.dart';
import 'package:snap_saver/widgets/darkroom_card.dart';
import 'package:snap_saver/widgets/darkroom_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Contact Developer
          DarkroomCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.contactDeveloper,
                      style: AppTypography.subheading()),
                ),
                IconButton(
                  onPressed: _showThanks,
                  icon: const Icon(Icons.thumb_up, color: AppColors.accent),
                ),
                IconButton(
                  onPressed: _launchMail,
                  icon: const Icon(Icons.mail, color: AppColors.accent2),
                ),
              ],
            ),
          ),

          // Browse Source Code
          DarkroomCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.browseSourceCode,
                      style: AppTypography.subheading()),
                ),
                IconButton(
                  onPressed: _launchGithub,
                  icon: const ImageIcon(
                    AssetImage('assets/icons/github_mark.png'),
                    size: 24.0,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),

          // Buy Coffee
          DarkroomCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.buy_me_coffee,
                      style: AppTypography.subheading()),
                ),
                IconButton(
                  onPressed: _launchCoffee,
                  icon: const Icon(Icons.coffee, color: AppColors.accent2),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showThanks() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.thankForCharlie),
        duration: const Duration(seconds: 2),
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
      DarkroomToast.show('☹️Failed to launch email');
    }
  }

  Future<void> _launchGithub() async {
    final Uri githubUrl = Uri.parse('https://github.com/NielsLee/SnapSaver');

    if (!await launchUrl(githubUrl)) {
      DarkroomToast.show('☹️Failed to launch Github');
    }
  }

  Future<void> _launchCoffee() async {
    final Uri coffeeUrl = Uri.parse('https://ko-fi.com/nielslee');

    DarkroomToast.show('😊Have a nice day!');

    await launchUrl(coffeeUrl);
  }
}
