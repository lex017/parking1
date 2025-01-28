import 'package:flutter/material.dart';

class GetImage extends StatefulWidget {
  const GetImage({super.key});

  @override
  State<GetImage> createState() => _GetImageState();
}

class _GetImageState extends State<GetImage> {
  // Replace this URL with your Cloudinary image URL
  final String cloudinaryImageUrl =
      "https://res.cloudinary.com/doiq3nkso/image/upload/v1234567890/xtltep94f5sgbfeuydnp.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Display Image from Cloudinary"),
      ),
      body: Center(
        child: cloudinaryImageUrl.isNotEmpty
            ? Image.network(
                cloudinaryImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Text("Failed to load image");
                },
              )
            : const Text("No image URL provided"),
      ),
    );
  }
}
