import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'app_runtime.dart';
import 'data/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppRuntime.isCameraPluginSupported) {
    try {
      AppRuntime.cameras = await availableCameras();
    } catch (_) {
      AppRuntime.cameras = <CameraDescription>[];
    }
  } else {
    AppRuntime.cameras = <CameraDescription>[];
  }

  await AppDatabase.instance.initialize();

  runApp(const ImpressionVaultApp());
}
