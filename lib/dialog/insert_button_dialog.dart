import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/viewmodel/dialog_view_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';


import '../file/android_native_path_picker.dart';

class InsertButtonDialog extends StatefulWidget {
  const InsertButtonDialog({super.key});

  @override
  State<StatefulWidget> createState() => InsertButtonDialogState();
}

class InsertButtonDialogState extends State<InsertButtonDialog> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => DialogViewModel(),
        child: Consumer<DialogViewModel>(
          builder: (_, dialogViewModel, __) {
            final nameController = TextEditingController();
            final pathController = TextEditingController();

            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.createANewSaver),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                            child: TextField(
                          controller: pathController,
                          readOnly: true,
                          decoration: InputDecoration(
                              label: Text(AppLocalizations.of(context)!.selectPath),
                              border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(18)))),
                        )),
                        Container(
                          color: Colors.transparent,
                          child: IconButton(
                              onPressed: () {
                                AndroidNativePathPicker().selectPath((path) {
                                  if (path != null) {
                                    pathController.text = path;
                                    nameController.text = basename(path);
                                  }
                                });
                              },
                              icon: Icon(Icons.file_copy)),
                        )
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(8)),
                    Row(
                      children: [
                        Expanded(
                            child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                              label: Text(AppLocalizations.of(context)!.name),
                              border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(18)))),
                        ))
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocalizations.of(context)!.cancel),
                  onPressed: () {
                    Vibration.vibrate(amplitude: 255, duration: 5);
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.ok),
                  onPressed: () {
                    Vibration.vibrate(amplitude: 255, duration: 5);
                    final inputName = nameController.text;
                    final inputPath = pathController.text;
                    if (inputName.isEmpty || inputPath.isEmpty) {
                    } else {
                      dialogViewModel.setName(inputName);
                      dialogViewModel.setPath(inputPath);
                      Navigator.of(context).pop(dialogViewModel);
                    }
                  },
                ),
              ],
            );
          },
        ));
  }
}
