import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/audio_channel.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  static const String _defaultUrl =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  final TextEditingController _urlController = TextEditingController(
    text: _defaultUrl,
  );
  String? _loadedUrl;
  bool _playing = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    AudioChannel.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      return;
    }

    try {
      if (_playing) {
        await AudioChannel.pause();
        setState(() => _playing = false);
        return;
      }

      if (_loadedUrl == url) {
        await AudioChannel.resume();
        setState(() => _playing = true);
        return;
      }

      await AudioChannel.play(url);
      setState(() {
        _loadedUrl = url;
        _playing = true;
        _error = null;
      });
    } on MissingPluginException {
      setState(() => _error = 'Audio playback is available on Android only.');
    } catch (_) {
      setState(() => _error = 'Could not play audio');
    }
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
              labelText: 'Audio URL',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) {
              if (!_playing) {
                _toggle();
              }
            },
          ),
          const SizedBox(height: 12),
          if (_error != null) ...[
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: Center(
              child: IconButton(
                iconSize: 48,
                onPressed: _toggle,
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
