import 'dart:io';

import 'package:flutter/material.dart';

class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final File imageFile = File(imagePath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Delete image',
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.delete_outline),
          )
        ],
      ),
      body: Center(
        child: imageFile.existsSync()
            ? InteractiveViewer(
                minScale: 0.6,
                maxScale: 4,
                child: Image.file(imageFile),
              )
            : const Text('Image not found'),
      ),
    );
  }
}
