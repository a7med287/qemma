import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ExploreImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget? fallback;

  const ExploreImage({
    super.key,
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }
    if (imageUrl!.startsWith('data:image/')) {
      try {
        final base64Str = imageUrl!.split(',').last;
        final Uint8List bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder ?? (_, __, ___) => fallback ?? const SizedBox.shrink(),
        );
      } catch (_) {
        return fallback ?? const SizedBox.shrink();
      }
    }
    return Image.network(
      imageUrl!,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder ?? (_, __, ___) => fallback ?? const SizedBox.shrink(),
    );
  }
}
