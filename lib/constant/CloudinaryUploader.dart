import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryUploader extends StatefulWidget {
  @override
  _CloudinaryUploaderState createState() => _CloudinaryUploaderState();
}

class _CloudinaryUploaderState extends State<CloudinaryUploader> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes; // ใช้สำหรับ Web
  File? _imageFile; // ใช้สำหรับ Mobile

  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking"; // Preset สำหรับการอัปโหลด

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          // สำหรับ Web
          final Uint8List bytes = await pickedFile.readAsBytes();
          setState(() {
            _imageBytes = bytes;
          });
        } else {
          // สำหรับ Mobile
          setState(() {
            _imageFile = File(pickedFile.path);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ยังไม่ได้เลือกรูปภาพ')),
        );
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเลือกภาพ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกภาพ')),
      );
    }
  }

  Future<void> _uploadImage() async {
    try {
      if (_imageBytes == null && _imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ยังไม่ได้เลือกรูปภาพเพื่ออัปโหลด')),
        );
        return;
      }

      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset;

      if (_imageBytes != null) {
        // สำหรับ Web
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _imageBytes!,
            filename: 'uploaded_image.jpg',
          ),
        );
      } else if (_imageFile != null) {
        // สำหรับ Mobile
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            _imageFile!.path,
          ),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = jsonDecode(responseData);
        final imageUrl = decodedData['secure_url'];
        print("อัปโหลดสำเร็จ: $imageUrl");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปโหลดสำเร็จ!')),
        );
      } else {
        print("การอัปโหลดล้มเหลว: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('การอัปโหลดล้มเหลว')),
        );
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดระหว่างการอัปโหลด: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดระหว่างการอัปโหลด')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cloudinary Image Uploader"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageBytes != null)
                Image.memory(
                  _imageBytes!,
                  width: 300,
                  height: 300,
                )
              else if (_imageFile != null)
                Image.file(
                  _imageFile!,
                  width: 300,
                  height: 300,
                )
              else
                Text("ยังไม่ได้เลือกรูปภาพ"),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text("เลือกรูปภาพ"),
              ),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text("อัปโหลดไปยัง Cloudinary"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
