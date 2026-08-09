import 'package:flutter/foundation.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Samsung/OneUI Android PhotoPicker can NPE-crash the picker process.
/// Force the legacy picker globally so every ImagePicker call site is safe.
void configureImagePickerForPlatform() {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android) return;
  final impl = ImagePickerPlatform.instance;
  if (impl is ImagePickerAndroid) {
    impl.useAndroidPhotoPicker = false;
  }
}
