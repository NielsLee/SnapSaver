
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snap_saver/viewmodel/dialog_view_model.dart';

class InsertButtonDialog extends StatefulWidget {
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
            final name = dialogViewModel.getName();
            final path = dialogViewModel.getPath();
            return AlertDialog(
              title: const Text('Create A New Saver'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Row(
                      children: [
                        Text("Name:"),
                        Expanded(child: TextField(
                          decoration: InputDecoration(
                              label: Text("Name"),
                              hintText: "Input Saver Name",
                              border: OutlineInputBorder()),
                        ))
                      ],
                    ),
                    Row(
                      children: [
                        Text('Path:'),
                        IconButton(onPressed: () {}, icon: Icon(Icons.file_copy))
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Approve'),
                  onPressed: () {
                    Navigator.of(context).pop(dialogViewModel);
                  },
                ),
              ],
            );
          },
        ));
  }
}