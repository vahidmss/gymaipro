import 'dart:typed_data';

/// Cross-platform picked/cropped profile image (web + mobile).
class PickedProfileImage {
  const PickedProfileImage({
    required this.bytes,
    this.fileName = 'avatar.jpg',
    this.mimeType = 'image/jpeg',
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}
