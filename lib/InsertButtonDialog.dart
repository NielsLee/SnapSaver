import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/viewmodel/dialog_view_model.dart';

import 'file/android_native_path_picker.dart';

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
              title: const Text('Create A New Saver'),
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
                              label: Text("Path"),
                              hintText: "Input Path",
                              border: OutlineInputBorder(
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
                              label: Text("Name"),
                              hintText: "Input Saver Name",
                              border: OutlineInputBorder(
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
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Approve'),
                  onPressed: () {
                    final inputName = nameController.text;
                    final inputPath = pathController.text;
                    if (inputName.isEmpty || inputPath.isEmpty) {
                      // 娌℃湁姝ｅ父鍒涘缓
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
