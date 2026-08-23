import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VideoPage extends StatelessWidget {
  const VideoPage({super.key});

  static const String _videoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const Center(
        child: Text('Video playback is available on Android only.'),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: AndroidView(
          viewType: 'assignment02/video',
          creationParams: const {'url': _videoUrl},
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        ),
      ),
    );
  }
}
