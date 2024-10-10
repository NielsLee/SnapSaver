import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/dialog/path_selector_entity.dart';
import 'package:snap_saver/viewmodel/dialog_view_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';

import '../file/android_native_path_picker.dart';

class InsertSaverDialog extends StatefulWidget {
  const InsertSaverDialog({super.key});

  @override
  State<StatefulWidget> createState() => InsertSaverDialogState();
}

class InsertSaverDialogState extends State<InsertSaverDialog> {
  // List for path selectors
  List<PathSelectorEntity> pathSelectors = [PathSelectorEntity()];
  // Controller for input saver name and paths
  TextEditingController nameController = TextEditingController();
  TextEditingController pathController = TextEditingController();

  // Indicates whether user has manually input path
  bool hasManuallyInputPath = false;
  // Color of the Saver button
  Color? saverColor = null;
  // Selected color index in color list
  int selectedColorIndex = -1;

  @override
  Widget build(BuildContext context) {
    final colorList = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.cyan,
      Colors.blue,
      Colors.purple
    ];

    return ChangeNotifierProvider(
        create: (_) => DialogViewModel(),
        child: Consumer<DialogViewModel>(
          builder: (_, dialogViewModel, __) {
            return AlertDialog(
              contentPadding: EdgeInsets.fromLTRB(16, 20, 16, 0),
              title: Text(AppLocalizations.of(context)!.createANewSaver),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    // Text field for input name of new saver
                    TextField(
                      controller: nameController,
                      onTap: () {
                        hasManuallyInputPath = true;
                      },
                      decoration: InputDecoration(
                          label: Text(AppLocalizations.of(context)!.saverName),
                          border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)))),
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
                                        // add selected path to viewmodel
                                        dialogViewModel.addPath(path);
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
                    }).toList()),

                    // Row for select saver color
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                          children: colorList.asMap().entries.map((colorEntry) {
                        return IconButton(
                          isSelected: selectedColorIndex == colorEntry.key,
                          selectedIcon: Icon(
                            Icons.check,
                            color: colorEntry.value,
                          ),
                          onPressed: () {
                            setState(() {
                              selectedColorIndex = colorEntry.key;
                            });
                          },
                          icon: Icon(Icons.folder, color: colorEntry.value),
                        );
                      }).toList()),
                    )
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
                      // no name or no path, do nothing
                    } else {
                      dialogViewModel.setName(inputName);
                      if (selectedColorIndex > 0) {
                        dialogViewModel.setColor(colorList[selectedColorIndex]);
                      }
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
