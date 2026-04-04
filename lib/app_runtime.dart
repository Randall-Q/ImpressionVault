import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class AppRuntime {
  static List<CameraDescription> cameras = <CameraDescription>[];

  static bool get isCameraPluginSupported {
    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
        return false;
    }
  }
}
