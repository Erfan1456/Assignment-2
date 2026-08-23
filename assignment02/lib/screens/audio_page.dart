import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/audio_channel.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  static const String _audioUrl =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  bool _started = false;
  bool _playing = false;
  String? _error;

  @override
  void dispose() {
    AudioChannel.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (_playing) {
        await AudioChannel.pause();
        setState(() => _playing = false);
      } else if (_started) {
        await AudioChannel.resume();
        setState(() => _playing = true);
      } else {
        await AudioChannel.play(_audioUrl);
        setState(() {
          _started = true;
          _playing = true;
        });
      }
    } on MissingPluginException {
      setState(() => _error = 'Audio playback is available on Android only.');
    } catch (_) {
      setState(() => _error = 'Could not play audio');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return Center(
      child: IconButton(
        iconSize: 48,
        onPressed: _toggle,
        icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
