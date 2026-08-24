import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  static const String _defaultUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  final TextEditingController _urlController = TextEditingController(
    text: _defaultUrl,
  );
  String _loadedUrl = _defaultUrl;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _load() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      return;
    }
    setState(() => _loadedUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Video URL',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _load(),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: const Text('Load')),
          const SizedBox(height: 16),
          Expanded(child: _player()),
        ],
      ),
    );
  }

  Widget _player() {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const Center(
        child: Text('Video playback is available on Android only.'),
      );
    }

    return AndroidView(
      key: ValueKey(_loadedUrl),
      viewType: 'assignment02/video',
      creationParams: {'url': _loadedUrl},
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }
}
