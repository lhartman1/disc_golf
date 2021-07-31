import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserImagePicker extends StatefulWidget {
  UserImagePicker(this.imagePickFn);

  final void Function(PickedFile pickedImage) imagePickFn;

  @override
  _UserImagePickerState createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  PickedFile? _pickedFile;

  void _pickImage() async {
    final pickedImageFile = await ImagePicker().getImage(
      // source: ImageSource.camera,
      source: ImageSource.gallery,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
      maxWidth: 150,
    );
    if (pickedImageFile == null) return;

    setState(() {
      _pickedFile = pickedImageFile;
    });
    widget.imagePickFn(_pickedFile!);
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_pickedFile != null) {
      imageProvider = kIsWeb
          ? NetworkImage(_pickedFile!.path)
          : FileImage(File(_pickedFile!.path)) as ImageProvider;
    }

    return Column(
      children: <Widget>[
        CircleAvatar(
          child: _pickedFile != null
              ? null
              : Icon(
                  Icons.person,
                  size: 64,
                  color: Colors.grey.shade200,
                ),
          radius: 40,
          backgroundColor: Colors.grey,
          backgroundImage: imageProvider,
        ),
        TextButton.icon(
          onPressed: _pickImage,
          icon: Icon(Icons.image),
          label: Text('Add Image'),
          style: TextButton.styleFrom(
            primary: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
