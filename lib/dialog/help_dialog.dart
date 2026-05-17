import 'package:snap_saver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:snap_saver/theme/theme.dart';

class HelpDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.howToUse,
          style: AppTypography.subheading()),
      content: Text(AppLocalizations.of(context)!.helpContent,
          style: AppTypography.body()),
    );
  }
}
