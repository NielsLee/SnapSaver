import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/dialog/path_selector_entity.dart';
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
  // List for path selectors
  List<PathSelectorEntity> pathSelectors = [PathSelectorEntity()];
  // Controller for input saver name and paths
  TextEditingController nameController = TextEditingController();
  TextEditingController pathController = TextEditingController();

  // Indicates whether user has manually input path
  bool hasManuallyInputPath = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => DialogViewModel(),
        child: Consumer<DialogViewModel>(
          builder: (_, dialogViewModel, __) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.createANewSaver),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                            child: TextField(
                          controller: nameController,
                          onTap: () {
                            hasManuallyInputPath = true;
                          },
                          decoration: InputDecoration(
                              label: Text(AppLocalizations.of(context)!.name),
                              border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)))),
                        ))
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(8)),
                    // Columns for path select
                    Column(
                        children: pathSelectors.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pathSelector = entry.value;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          //when path is not selected, show the select button
                          Visibility(
                              visible: !pathSelector.isPathSelected,
                              child: Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    AndroidNativePathPicker()
                                        .selectPath((path) {
                                      if (path != null) {
                                        pathController.text = path;

                                        if (!hasManuallyInputPath) {
                                          // if user doesn't input name manually, use path's basename as default
                                          nameController.text += basename(path);
                                          nameController.text += " ";
                                        }

                                        setState(() {
                                          pathSelector.path = path;
                                          pathSelector.isPathSelected = true;
                                        });
                                      }
                                    });
                                  },
                                  child: Text("Select Path"),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                    ),
                                  ),
                                ),
                              )),

                          // if path is selected, show the path
                          Visibility(
                              visible: pathSelector.isPathSelected,
                              child: Expanded(
                                child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(pathSelector.path.toString())),
                              )),

                          // if this is the last column, show add button
                          Visibility(
                              visible: index == pathSelectors.length - 1,
                              child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      pathSelectors.add(PathSelectorEntity());
                                      print(pathSelectors.map((entity) {
                                        entity.path.toString();
                                      }).toList());
                                    });
                                  },
                                  icon: Icon(Icons.add))),

                          // if path is selected, show edit button
                          Visibility(
                              visible: pathSelector.isPathSelected,
                              child: IconButton(
                                  onPressed: () {
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.edit))),

                          // if more than one column(path selector) exist, show remove button
                          Visibility(
                              visible: pathSelectors.length != 1,
                              child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      pathSelectors.removeAt(index);
                                    });
                                  },
                                  icon: Icon(Icons.remove)))
                        ],
                      );
                    }).toList())
                  ],
                ),
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
                    String inputName = nameController.text;
                    final inputPath = pathController.text;

                    List<String?> avaliablePaths = pathSelectors.map(
                      (selector) {
                        if (selector.isPathSelected) return selector.path;
                      },
                    ).toList();

                    print("name:$inputName, path: $inputPath");
                    if (inputName.isEmpty || avaliablePaths.isEmpty) {
                      // do nothing
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
