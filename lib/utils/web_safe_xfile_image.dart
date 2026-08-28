import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Preview an [XFile] without [Image.file] / dart:io (Safari-safe).
class WebSafeXFileImage extends StatefulWidget {
  const WebSafeXFileImage({
    required this.file,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    super.key,
  });

  final XFile file;
  final BoxFit fit;
  final Widget Function(BuildContext context)? errorBuilder;

  @override
  State<WebSafeXFileImage> createState() => _WebSafeXFileImageState();
}

class _WebSafeXFileImageState extends State<WebSafeXFileImage> {
  late final Future<Uint8List> _bytesFuture = widget.file.readAsBytes();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: widget.fit,
            gaplessPlayback: true,
          );
        }
        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context) ??
              const ColoredBox(
                color: Colors.black12,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              );
        }
        return const ColoredBox(
          color: Colors.black12,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
