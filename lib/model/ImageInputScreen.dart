import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageInputScreen extends StatefulWidget {
  const ImageInputScreen({super.key});

  @override
  State<ImageInputScreen> createState() => _ImageInputScreenState();
}

class _ImageInputScreenState extends State<ImageInputScreen> {
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    // Pick an image from the gallery
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Convert the image to Uint8List for Flutter Web
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = imageBytes;
      });
    }
  }

  Future<void> _captureImage() async {
    // Capture an image using the camera
    final capturedFile = await _picker.pickImage(source: ImageSource.camera);

    if (capturedFile != null) {
      // Convert the image to Uint8List for Flutter Web
      final imageBytes = await capturedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = imageBytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Input Example"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _selectedImageBytes != null
                ? Image.memory(
                    _selectedImageBytes!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : const Icon(
                    Icons.image,
                    size: 200,
                    color: Colors.grey,
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Pick Image from Gallery"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _captureImage,
              child: const Text("Capture Image using Camera"),
            ),
          ],
        ),
      ),
    );
  }
}
