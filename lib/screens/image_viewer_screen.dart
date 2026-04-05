import 'dart:io';

import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/customer_image_record.dart';

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.customerId,
  });

  final List<CustomerImageRecord> images;
  final int initialIndex;
  final int customerId;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late List<CustomerImageRecord> _images;
  late PageController _pageController;
  late int _currentIndex;
  bool _didChange = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _images = List<CustomerImageRecord>.of(widget.images);
    _currentIndex =
        widget.initialIndex.clamp(0, _images.isEmpty ? 0 : _images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deleteCurrentImage() async {
    if (_isDeleting || _images.isEmpty) {
      return;
    }

    final int imageNumber = _currentIndex + 1;
    final int imageCount = _images.length;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: Text(
            'Are you sure you want to delete image $imageNumber of $imageCount?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final CustomerImageRecord image = _images[_currentIndex];

    setState(() {
      _isDeleting = true;
    });

    try {
      if (image.id != null) {
        await AppDatabase.instance.deleteImage(image.id!);
      }
      await AppDatabase.instance.touchCustomer(widget.customerId);

      final File imageFile = File(image.path);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      _didChange = true;

      if (!mounted) {
        return;
      }

      if (_images.length == 1) {
        Navigator.of(context).pop(true);
        return;
      }

      final int nextIndex = _currentIndex >= _images.length - 1
          ? _images.length - 2
          : _currentIndex;
      final PageController oldController = _pageController;

      setState(() {
        _images.removeAt(_currentIndex);
        _currentIndex = nextIndex;
        _pageController = PageController(initialPage: _currentIndex);
      });

      oldController.dispose();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImages = _images.isNotEmpty;
    final String title = hasImages
        ? 'Image ${_currentIndex + 1} of ${_images.length}'
        : 'Images';

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_didChange);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              tooltip: 'Delete image',
              onPressed: hasImages && !_isDeleting ? _deleteCurrentImage : null,
              icon: const Icon(Icons.delete_outline),
            )
          ],
        ),
        body: hasImages
            ? Stack(
                children: <Widget>[
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _images.length,
                    onPageChanged: (int index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final File imageFile = File(_images[index].path);

                      return Center(
                        child: imageFile.existsSync()
                            ? InteractiveViewer(
                                minScale: 0.6,
                                maxScale: 4,
                                child: Image.file(imageFile),
                              )
                            : const Text('Image not found'),
                      );
                    },
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${_images.length}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(child: Text('No images available')),
      ),
    );
  }
}
