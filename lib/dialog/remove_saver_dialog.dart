import 'package:flutter/material.dart';
import 'package:snap_saver/entity/saver.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RemoveSaverDialog extends StatelessWidget {
  Saver saver;
  RemoveSaverDialog({super.key, required this.saver});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(AppLocalizations.of(context)!.removeSaver),
          Spacer(),
          if (saver.color != null)
            Icon(
              Icons.folder,
              color: Color(saver.color!),
            )
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.name + ":"),
          Text(
            saver.name,
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          Padding(padding: EdgeInsets.all(8)),
          Text(AppLocalizations.of(context)!.path + ":"),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: saver.paths.map((path) {
              return Text(path);
            }).toList(),
          )
        ],
      ),
      actions: <Widget>[
        // cancel button
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () {
            Vibration.vibrate(amplitude: 255, duration: 5);
            Navigator.of(context).pop();
          },
        ),

        // ok button
        TextButton(
          child: Text(AppLocalizations.of(context)!.ok),
          onPressed: () {
            Vibration.vibrate(amplitude: 255, duration: 5);
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
