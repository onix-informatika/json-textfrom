import 'dart:io';

// import 'package:file_picker/file_picker.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/material.dart';
import '../models/Schema.dart';
import '../models/components/FileFieldValue.dart';
import '../utils-components/OutlineButtonContainer.dart';

import '../JSONForm.dart';

typedef void OnChange(FileFieldValue value);

class JSONFileField extends StatelessWidget {
  final OnFileUpload onFileUpload;
  final Schema schema;
  final OnChange onSaved;
  final bool showIcon;
  final bool isOutlined;
  final bool filled;
  final Key key;

  JSONFileField({
    @required this.schema,
    @required this.onFileUpload,
    this.key,
    this.onSaved,
    this.showIcon = true,
    this.isOutlined = false,
    this.filled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FileFieldValue value;
    if (schema.value == null) {
      value = FileFieldValue();
    } else if (schema.value is! FileFieldValue) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: Text(
          "Value is not supported",
          style: TextStyle(color: Colors.red),
        ),
      );
    } else {
      value = schema.value;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: OutlineButtonContainer(
        isFilled: filled,
        isOutlined: isOutlined,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(schema.label),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Wrap(
                      children: <Widget>[
                        if (value.path != null)
                          Chip(
                            label: Text(
                              "Old: ${value.path}",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                decoration: value.willClear
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            deleteIcon: !value.willClear
                                ? Icon(
                                    Icons.cancel,
                                    key: Key("Delete Old"),
                                  )
                                : Icon(
                                    Icons.restore,
                                    key: Key("Restore"),
                                  ),
                            onDeleted: () {
                              if (value.willClear) {
                                value.restoreOld();
                              } else {
                                value.clearOld();
                              }
                              onSaved(value);
                            },
                          ),
                        SizedBox(
                          width: 10,
                        ),
                        if (value.file != null)
                          Chip(
                            label: Text(
                              "New: ${value.file.path}",
                              maxLines: 1,
                            ),
                            deleteIcon: Icon(
                              Icons.cancel,
                              key: Key("Delete New"),
                            ),
                            onDeleted: () {
                              value.clearNew();
                              onSaved(value);
                            },
                          )
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key("Upload"),
                    onPressed: () async {
                      // TODO ??
                      // File file;
                      // if (onFileUpload != null) {
                      //   file = await onFileUpload(schema.name);
                      // } else {
                      //   FilePickerCross filePickerCross = FilePickerCross();
                      //   try {
                      //     await filePickerCross.pick();
                      //     file = File(filePickerCross.path);
                      //   } catch (err) {}
                      // }
                      // value.file = file;
                      // if (file != null) {
                      //   onSaved(value);
                      // }
                    },
                    icon: Icon(Icons.file_upload),
                  )
                ],
              ),
              Divider(
                color: Theme.of(context).textTheme.bodyText1.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
