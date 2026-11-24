import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget multiplataforma para renderizar un [XFile] tanto en Web como en Móvil/Desktop.
/// Evita el fallo de aserción `!kIsWeb` en Flutter Web al no invocar `Image.file`.
class XFileImageWidget extends StatelessWidget {
  final XFile file;
  final BoxFit fit;
  final double? width;
  final double? height;

  const XFileImageWidget({
    super.key,
    required this.file,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return FutureBuilder<Uint8List>(
            future: file.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Image.memory(
                  snapshot.data!,
                  fit: fit,
                  width: width,
                  height: height,
                );
              }
              return SizedBox(
                width: width,
                height: height,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          );
        },
      );
    }

    return Image.file(
      File(file.path),
      fit: fit,
      width: width,
      height: height,
    );
  }
}

