import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:snap_saver/entity/more.dart';

class MoreDialog extends StatefulWidget {
  final String? initialPhotoName;
  final int? initialSuffixType;
  
  const MoreDialog({super.key, this.initialPhotoName, this.initialSuffixType});

  @override
  State<StatefulWidget> createState() => MoreDialogState();
}

class MoreDialogState extends State<MoreDialog> {
  TextEditingController fileNameController = TextEditingController();
  String examplePhotoName = "";

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // 如果有初始值，设置一下
    if (widget.initialPhotoName != null) {
      fileNameController.text = widget.initialPhotoName!;
    }
    if (widget.initialSuffixType != null) {
      _selectedIndex = widget.initialSuffixType!;
    }

    _refreshExamplePhotoName();
  }

  void _refreshExamplePhotoName() {
    String newValue = fileNameController.text;
    switch (_selectedIndex) {
      case 0:
        {
          examplePhotoName = newValue + "1" + '\n' + newValue + "2";
          break;
        }
      case 1:
        {
          DateTime now = DateTime.now();
          DateTime yesterday = now.subtract(const Duration(days: 1));

          String nowStr = DateFormat('yyyyMMddHHmmss').format(now);
          String yesterdayStr = DateFormat('yyyyMMddHHmmss').format(yesterday);
          examplePhotoName = newValue + nowStr + '\n' + newValue + yesterdayStr;
          break;
        }
      case 2:
        {
          examplePhotoName = newValue + "_1" + '\n' + newValue + "_2";
          break;
        }
      case 3:
        {
          DateTime now = DateTime.now();
          DateTime yesterday = now.subtract(const Duration(days: 1));

          String nowStr = DateFormat('yyyyMMddHHmmss').format(now);
          String yesterdayStr = DateFormat('yyyyMMddHHmmss').format(yesterday);
          examplePhotoName =
              newValue + '_' + nowStr + '\n' + newValue + '_' + yesterdayStr;
          break;
        }
      case 4:
        {
          examplePhotoName = newValue + "-1" + '\n' + newValue + "-2";
          break;
        }
      case 5:
        {
          DateTime now = DateTime.now();
          DateTime yesterday = now.subtract(const Duration(days: 1));

          String nowStr = DateFormat('yyyyMMddHHmmss').format(now);
          String yesterdayStr = DateFormat('yyyyMMddHHmmss').format(yesterday);
          examplePhotoName =
              newValue + '-' + nowStr + '\n' + newValue + '-' + yesterdayStr;
          break;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _typeList = [
      AppLocalizations.of(context)!.photoIndex,
      AppLocalizations.of(context)!.photoTimestamp,
      "_" + AppLocalizations.of(context)!.photoIndex,
      "_" + AppLocalizations.of(context)!.photoTimestamp,
      "-" + AppLocalizations.of(context)!.photoIndex,
      "-" + AppLocalizations.of(context)!.photoTimestamp,
    ];

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.more),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.photoName),
          Row(
            children: [
              Expanded(
                  flex: 1,
                  child: TextField(
                    controller: fileNameController,
                    onTap: () {},
                    onChanged: (newValue) {
                      setState(() {
                        _refreshExamplePhotoName();
                      });
                    },
                    decoration: InputDecoration(
                        label: Text(
                            AppLocalizations.of(context)!.photoNameDescription),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12)))),
                  )),
              Text(" + "),
              DropdownButton<String>(
                value: _typeList[_selectedIndex],
                items: _typeList.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    if (newValue != null) {
                      _selectedIndex = _typeList.indexOf(newValue);
                    }
                    _refreshExamplePhotoName();
                  });
                },
              )
            ],
          ),
          Text(AppLocalizations.of(context)!.photoNameExample + ':'),
          Text(examplePhotoName)
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.cancel)),
        TextButton(
            onPressed: () {
              var name = fileNameController.text;
              if (name.isEmpty) {
                // no name input, use default
                Navigator.of(context).pop();
                return;
              }
              var more = More(photoName: name, suffixType: _selectedIndex);
              Navigator.of(context).pop(more);
            },
            child: Text(AppLocalizations.of(context)!.ok)),
      ],
    );
  }
}
