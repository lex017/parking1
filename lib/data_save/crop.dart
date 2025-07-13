import 'dart:io'; // Add this import for File

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class Croper extends StatefulWidget {
  final CroppedFile image;
  const Croper({super.key, required this.image});

  @override
  State<Croper> createState() => _CroperState();
}

class _CroperState extends State<Croper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cropper Image'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: InteractiveViewer(
            child: Image(image: FileImage(File(widget.image.path))), // ✅ FIXED
          ),
        ),
      ),
    );
  }
}
