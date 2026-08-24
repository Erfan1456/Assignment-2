import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/media_channel.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  static const String _audioAsset = 'assets/media/sample_audio.mp3';

  StreamSubscription<Map<dynamic, dynamic>>? _subscription;
  bool _started = false;
  bool _playing = false;
  bool _seeking = false;
  int _positionMs = 0;
  int _durationMs = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = MediaChannel.events().listen(_onEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    MediaChannel.audioStop();
    super.dispose();
  }

  void _onEvent(Map<dynamic, dynamic> event) {
    if (event['player'] != 'audio' || !mounted) {
      return;
    }
    if (event['event'] == 'error') {
      if (_playing || _started) {
        return;
      }
      setState(() => _error = event['message']?.toString() ?? 'Could not play audio');
      return;
    }

    setState(() {
      _started = true;
      _playing = event['playing'] == true && event['event'] != 'complete';
      if (!_seeking) {
        _positionMs = (event['position'] as num?)?.toInt() ?? _positionMs;
      }
      _durationMs = (event['duration'] as num?)?.toInt() ?? _durationMs;
      if (event['event'] == 'complete') {
        _playing = false;
        _positionMs = _durationMs;
      }
    });
  }

  Future<void> _togglePlay() async {
    try {
      if (_playing) {
        await MediaChannel.audioPause();
        setState(() => _playing = false);
        return;
      }

      if (_started && _positionMs < _durationMs) {
        await MediaChannel.audioResume();
        setState(() {
          _playing = true;
          _error = null;
        });
        return;
      }

      final info = await MediaChannel.audioPlay(_audioAsset);
      setState(() {
        _started = true;
        _playing = true;
        _error = null;
        _positionMs = 0;
        _durationMs = (info['duration'] as num?)?.toInt() ?? 0;
      });
    } on MissingPluginException {
      setState(() => _error = 'Audio playback is available on Android only.');
    } catch (_) {
      setState(() => _error = 'Could not play audio');
    }
  }

  Future<void> _stop() async {
    await MediaChannel.audioStop();
    setState(() {
      _started = false;
      _playing = false;
      _positionMs = 0;
      _durationMs = 0;
    });
  }

  Future<void> _skip(int ms) async {
    if (!_started || _durationMs == 0) {
      return;
    }
    final next = (_positionMs + ms).clamp(0, _durationMs);
    await MediaChannel.audioSeek(next);
    setState(() => _positionMs = next);
  }

  String _time(int ms) {
    final d = Duration(milliseconds: ms < 0 ? 0 : ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.audiotrack, size: 88),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
          ],
          Slider(
            value: _durationMs == 0
                ? 0
                : _positionMs.clamp(0, _durationMs).toDouble(),
            max: (_durationMs == 0 ? 1 : _durationMs).toDouble(),
            onChangeStart: _started
                ? (_) => setState(() => _seeking = true)
                : null,
            onChanged: _started
                ? (value) => setState(() => _positionMs = value.toInt())
                : null,
            onChangeEnd: _started
                ? (value) async {
                    await MediaChannel.audioSeek(value.toInt());
                    setState(() => _seeking = false);
                  }
                : null,
          ),
          Row(
            children: [
              Text(_time(_positionMs)),
              const Spacer(),
              Text(_time(_durationMs)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _started ? () => _skip(-10000) : null,
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
              ),
              IconButton(
                onPressed: _togglePlay,
                icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
                iconSize: 64,
              ),
              IconButton(
                onPressed: _started ? _stop : null,
                icon: const Icon(Icons.stop_circle),
                iconSize: 40,
              ),
              IconButton(
                onPressed: _started ? () => _skip(10000) : null,
                icon: const Icon(Icons.forward_10),
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
