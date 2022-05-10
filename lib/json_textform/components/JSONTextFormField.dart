import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:json_schema_form/json_textform/models/components/Action.dart';
import 'package:json_schema_form/json_textform/models/components/AvaliableWidgetTypes.dart';
import 'package:json_schema_form/json_textform/models/Schema.dart';

class JSONTextFormField extends StatefulWidget {
  final Schema schema;
  final Function onSaved;
  final bool isOutlined;
  final bool filled;

  JSONTextFormField(
      {@required this.schema,
      this.onSaved,
      this.isOutlined = false,
      Key key,
      @required this.filled})
      : super(key: key);

  @override
  _JSONTextFormFieldState createState() => _JSONTextFormFieldState();
}

class _JSONTextFormFieldState extends State<JSONTextFormField> {
  TextEditingController _controller;
  bool multiLine = false;
  dynamic customActionValue;

  @override
  void initState() {
    super.initState();
    multiLine = widget.schema.validation?.length?.maximum == null &&
        widget.schema.widget == WidgetType.text;
    init();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(JSONTextFormField oldWidget) {
    if (oldWidget.schema.value != widget.schema.value) {
      Future.delayed(Duration(milliseconds: 50)).then((value) => init());
    }
    super.didUpdateWidget(oldWidget);
  }

  void init() {
    String value = widget.schema.value?.toString() ??
        widget.schema.extra?.defaultValue?.toString() ??
        "";

    if (_controller == null) {
      _controller = TextEditingController(text: value);
    } else {
      _controller.text = value;
    }
  }

  // ignore: missing_return
  String validation(String value) {
    switch (widget.schema.widget) {
      case WidgetType.number:
        final n = num.tryParse(value);
        if (n == null) {
          return '$value is not a valid number';
        }
        break;
      default:
        if ((value == null || value == "") && widget.schema.isRequired) {
          return "This field is required";
        }
    }
  }

  _suffixIconAction({File image, String inputValue}) async {
    switch (widget.schema.action.actionDone) {
      case ActionDone.getInput:
        if (inputValue != null) {
          setState(() {
            _controller.text = inputValue.toString();
          });
        } else if (image != null) {
          var value =
              await (widget.schema.action as FieldAction<File>).onDone(image);
          if (value is String) {
            setState(() {
              _controller.text = value;
            });
          }
        }
        break;

      case ActionDone.getImage:
        if (image != null) {
          await (widget.schema.action as FieldAction<File>).onDone(image);
        }
        break;
    }
  }

  Widget _renderSuffixIcon() {
    if (widget.schema.action != null) {
      switch (widget.schema.action.actionTypes) {
        case ActionTypes.image:
          return IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => Container(
                  child: Wrap(
                    children: <Widget>[
                      Platform.isAndroid || Platform.isIOS
                          ? ListTile(
                              leading: Icon(Icons.camera_alt),
                              title: Text("From Camera"),
                              onTap: () async {
                                ImagePicker imagePicker = ImagePicker();
                                var pickedFile = await imagePicker.getImage(
                                  source: ImageSource.camera,
                                );
                                File file = File(pickedFile.path);
                                await _suffixIconAction(image: file);
                              },
                            )
                          : Container(),
                      ListTile(
                        leading: Icon(Icons.filter),
                        title: Text("From Gallery"),
                        onTap: () async {
                          if (Platform.isIOS || Platform.isAndroid) {
                            ImagePicker imagePicker = ImagePicker();
                            var pickedFile = await imagePicker.getImage(
                              source: ImageSource.gallery,
                            );
                            File file = File(pickedFile.path);
                            await _suffixIconAction(image: file);
                          } else if (Platform.isMacOS) {
                            // TODO ??
                            // FilePickerCross filePickerCross = FilePickerCross();
                            // await filePickerCross.pick();
                            // File file = File(filePickerCross.path);
                            // await _suffixIconAction(image: file);
                          }
                        },
                      )
                    ],
                  ),
                ),
              );
            },
            icon: Icon(Icons.camera_alt),
          );

        case ActionTypes.qrScan:
          return IconButton(
            onPressed: () async {
              if (Platform.isAndroid || Platform.isIOS) {
                try {
                  var result = await BarcodeScanner.scan();
                  await _suffixIconAction(inputValue: result.rawContent);
                } on PlatformException catch (e) {
                  print(e);
                } on FormatException {
                } catch (e) {
                  print("format error: $e");
                }
              } else if (Platform.isMacOS) {
                //TODO: Add macOS support
              }
            },
            icon: Icon(Icons.camera_alt),
          );
          break;
        case ActionTypes.custom:
          return IconButton(
            icon: Icon(widget.schema.action.icon),
            onPressed: () async {
              if (widget.schema.action.onActionTap != null) {
                var value =
                    await widget.schema.action.onActionTap(widget.schema);
                await _suffixIconAction(inputValue: value);
              }
            },
          );
          break;
      }
    }
    return null;
  }

  TextInputType _getTextInputType() {
    if (widget.schema.widget == WidgetType.number) {
      return TextInputType.numberWithOptions(signed: true, decimal: true);
    }

    if (widget.schema.name == "email") {
      return TextInputType.emailAddress;
    }

    if (multiLine) {
      return TextInputType.multiline;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: TextFormField(
          onChanged: (value) {
            widget.onSaved(value);
          },
          key: Key("textfield-${widget.schema.name}"),
          maxLines: multiLine ? 10 : 1,
          controller: _controller,
          keyboardType: _getTextInputType(),
          validator: this.validation,
          maxLength: widget.schema.validation?.length?.maximum,
          obscureText: widget.schema.name == "password",
          decoration: InputDecoration(
            filled: widget.filled,
            helperText: widget.schema.extra?.helpText,
            labelText: widget.schema.label,
            prefixIcon: widget.schema.icon != null
                ? Icon(widget.schema.icon.iconData)
                : null,
            suffixIcon: _renderSuffixIcon(),
            border: widget.isOutlined == true
                ? OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(10.0),
                    ),
                  )
                : null,
          ),
          onSaved: this.widget.onSaved,
        ),
      ),
    );
  }
}
