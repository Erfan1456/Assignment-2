import 'package:flutter/material.dart';

class ImageScalePage extends StatelessWidget {
  const ImageScalePage({super.key});

  static const String _imageUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg';

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Image.network(
          _imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Text('Could not load image'));
          },
        ),
      ),
    );
  }
}
