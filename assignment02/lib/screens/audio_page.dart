import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  static const String _audioAsset = 'media/sample_audio.mp3';

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;
  bool _started = false;
  bool _playing = false;
  bool _seeking = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    _positionSub = _player.onPositionChanged.listen((position) {
      if (!_seeking && mounted) {
        setState(() => _position = position);
      }
    });
    _durationSub = _player.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = _duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_playing) {
        await _player.pause();
        setState(() => _playing = false);
        return;
      }

      if (_started && _position < _duration) {
        await _player.resume();
        setState(() {
          _playing = true;
          _error = null;
        });
        return;
      }

      await _player.play(AssetSource(_audioAsset));
      setState(() {
        _started = true;
        _playing = true;
        _error = null;
        _position = Duration.zero;
      });
    } catch (_) {
      setState(() => _error = 'Could not play audio');
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    setState(() {
      _started = false;
      _playing = false;
      _position = Duration.zero;
    });
  }

  Future<void> _skip(int ms) async {
    if (!_started || _duration == Duration.zero) {
      return;
    }
    final next = _position + Duration(milliseconds: ms);
    final clamped = next < Duration.zero
        ? Duration.zero
        : (next > _duration ? _duration : next);
    await _player.seek(clamped);
    setState(() => _position = clamped);
  }

  String _time(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = _duration.inMilliseconds;
    final positionMs = _position.inMilliseconds.clamp(
      0,
      durationMs == 0 ? 0 : durationMs,
    );

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
            value: durationMs == 0 ? 0 : positionMs.toDouble(),
            max: (durationMs == 0 ? 1 : durationMs).toDouble(),
            onChangeStart: _started
                ? (_) => setState(() => _seeking = true)
                : null,
            onChanged: _started
                ? (value) {
                    setState(
                      () => _position = Duration(milliseconds: value.toInt()),
                    );
                  }
                : null,
            onChangeEnd: _started
                ? (value) async {
                    await _player.seek(Duration(milliseconds: value.toInt()));
                    setState(() => _seeking = false);
                  }
                : null,
          ),
          Row(
            children: [
              Text(_time(_position)),
              const Spacer(),
              Text(_time(_duration)),
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
