import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_runtime.dart';
import '../data/app_database.dart';
import '../models/customer_image_record.dart';
import 'customer_form_screen.dart';
import 'image_viewer_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key, required this.customerId});

  final int customerId;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _cameraController;
  Future<void>? _cameraInitFuture;
  bool _isCapturing = false;
  bool _isInitializingCamera = false;
  String? _cameraErrorMessage;
  List<CustomerImageRecord> _images = <CustomerImageRecord>[];

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadImages();
  }

  Future<void> _initCamera() async {
    final CameraController? oldController = _cameraController;
    _cameraController = null;
    _cameraInitFuture = null;
    await oldController?.dispose();

    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializingCamera = true;
      _cameraErrorMessage = null;
    });

    try {
      if (!AppRuntime.isCameraPluginSupported) {
        if (!mounted) {
          return;
        }
        setState(() {
          _cameraErrorMessage =
              'Camera capture is not supported on this platform build.';
        });
        return;
      }

      if (AppRuntime.cameras.isEmpty) {
        AppRuntime.cameras = await availableCameras();
      }

      if (AppRuntime.cameras.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _cameraErrorMessage =
              'No camera was detected. Connect a camera and try again.';
        });
        return;
      }

      final CameraDescription camera = AppRuntime.cameras.firstWhere(
        (CameraDescription c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => AppRuntime.cameras.first,
      );

      final CameraController controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      final Future<void> initFuture = controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraInitFuture = initFuture;
      });

      await initFuture;
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraController = null;
        _cameraInitFuture = null;
        _cameraErrorMessage = _cameraErrorFromException(error);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraController = null;
        _cameraInitFuture = null;
        _cameraErrorMessage = 'Unable to initialize camera: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
        });
      }
    }
  }

  String _cameraErrorFromException(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'Camera permission is denied. Enable camera access in system settings and retry.';
      case 'AudioAccessDenied':
      case 'AudioAccessDeniedWithoutPrompt':
      case 'AudioAccessRestricted':
        return 'Microphone permission is denied. This app does not record audio, but your platform may still require access.';
      default:
        return 'Camera unavailable: ${error.description ?? error.code}';
    }
  }

  String _cameraDiagnosticsText() {
    final int cameraCount = AppRuntime.cameras.length;
    final CameraDescription? selected = _cameraController?.description;
    final String selectedName = selected?.name ?? 'none';
    final String lens = selected?.lensDirection.name ?? 'n/a';
    final String initState = _isInitializingCamera
        ? 'initializing'
        : _cameraController == null
        ? 'not ready'
        : 'ready';
    return 'Detected: $cameraCount | Selected: $selectedName ($lens) | State: $initState';
  }

  Future<void> _loadImages() async {
    final List<CustomerImageRecord> images =
        await AppDatabase.instance.listImagesForCustomer(widget.customerId);
    if (!mounted) {
      return;
    }
    setState(() {
      _images = images;
    });
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || _cameraInitFuture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _cameraErrorMessage ?? 'No camera is available on this device.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      await _cameraInitFuture;
      final XFile rawFile = await _cameraController!.takePicture();

      final Directory docsDir = await getApplicationDocumentsDirectory();
      final Directory imageDir = Directory(p.join(docsDir.path, 'customer_images'));
      if (!imageDir.existsSync()) {
        await imageDir.create(recursive: true);
      }

      final String filename =
          '${widget.customerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String targetPath = p.join(imageDir.path, filename);
      await File(rawFile.path).copy(targetPath);

      await AppDatabase.instance.addCustomerImage(
        CustomerImageRecord(
          customerId: widget.customerId,
          path: targetPath,
          createdAt: DateTime.now(),
        ),
      );
      await AppDatabase.instance.touchCustomer(widget.customerId);

      await _loadImages();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _openViewer(CustomerImageRecord image) async {
    final bool? shouldDelete = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ImageViewerScreen(
          imagePath: image.path,
        ),
      ),
    );

    if (shouldDelete != true || image.id == null) {
      return;
    }

    await AppDatabase.instance.deleteImage(image.id!);
    await AppDatabase.instance.touchCustomer(widget.customerId);

    final File imageFile = File(image.path);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }

    await _loadImages();
  }

  Future<void> _editDemographics() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerFormScreen(
          customerId: widget.customerId,
          returnToCaller: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Capture'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _editDemographics,
            icon: const Icon(Icons.edit_note),
            label: const Text('Edit Demographics'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth > 980;

          if (wide) {
            return Row(
              children: <Widget>[
                Expanded(flex: 7, child: _buildCameraSection()),
                const VerticalDivider(width: 1),
                Expanded(flex: 4, child: _buildImageList(vertical: true)),
              ],
            );
          }

          return Column(
            children: <Widget>[
              Expanded(child: _buildCameraSection()),
              SizedBox(height: 132, child: _buildImageList(vertical: false)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraSection() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black,
                child: _isInitializingCamera
                    ? const Center(child: CircularProgressIndicator())
                    : _cameraController == null || _cameraInitFuture == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                _cameraErrorMessage ?? 'Camera unavailable',
                                style: const TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _initCamera,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry Camera'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : FutureBuilder<void>(
                        future: _cameraInitFuture,
                        builder:
                            (BuildContext context, AsyncSnapshot<void> snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      'Camera failed to start: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: _initCamera,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry Camera'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return CameraPreview(_cameraController!);
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _cameraDiagnosticsText(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _isCapturing ? null : _captureImage,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_isCapturing ? 'Capturing...' : 'Capture Image'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Done'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildImageList({required bool vertical}) {
    if (_images.isEmpty) {
      return const Center(child: Text('No images captured yet'));
    }

    if (vertical) {
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (BuildContext context, int index) {
          return _buildImageTile(_images[index], vertical: true);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: _images.length,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int index) {
        return _buildImageTile(_images[index], vertical: false);
      },
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemCount: _images.length,
    );
  }

  Widget _buildImageTile(CustomerImageRecord image, {required bool vertical}) {
    final File file = File(image.path);
    final bool exists = file.existsSync();

    return InkWell(
      onTap: () => _openViewer(image),
      child: Container(
        width: vertical ? null : 120,
        height: vertical ? 110 : 110,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: exists
            ? Image.file(file, fit: BoxFit.cover)
            : const ColoredBox(
                color: Colors.black12,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
      ),
    );
  }
}
