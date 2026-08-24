import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/media_channel.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  static const String _videoAsset = 'assets/media/sample_video.mp4';

  StreamSubscription<Map<dynamic, dynamic>>? _subscription;
  int? _textureId;
  bool _ready = false;
  bool _playing = false;
  bool _muted = false;
  bool _seeking = false;
  int _positionMs = 0;
  int _durationMs = 0;
  double _aspect = 16 / 9;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = MediaChannel.events().listen(_onEvent);
    _start();
  }

  Future<void> _start() async {
    try {
      final info = await MediaChannel.videoInit(_videoAsset);
      final width = (info['width'] as num?)?.toDouble() ?? 0;
      final height = (info['height'] as num?)?.toDouble() ?? 0;
      if (mounted) {
        setState(() {
          _textureId = info['textureId'] as int?;
          _durationMs = (info['duration'] as num?)?.toInt() ?? 0;
          _ready = true;
          _playing = true;
          if (width > 0 && height > 0) {
            _aspect = width / height;
          }
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() => _error = 'Video playback is available on Android only.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not play video');
      }
    }
  }

  void _onEvent(Map<dynamic, dynamic> event) {
    if (event['player'] != 'video' || !mounted) {
      return;
    }
    if (event['event'] == 'error') {
      if (_playing || _ready) {
        return;
      }
      setState(() => _error = event['message']?.toString() ?? 'Could not play video');
      return;
    }

    final width = (event['width'] as num?)?.toDouble() ?? 0;
    final height = (event['height'] as num?)?.toDouble() ?? 0;
    setState(() {
      _ready = true;
      _playing = event['playing'] == true && event['event'] != 'complete';
      _muted = event['muted'] == true;
      if (!_seeking) {
        _positionMs = (event['position'] as num?)?.toInt() ?? _positionMs;
      }
      _durationMs = (event['duration'] as num?)?.toInt() ?? _durationMs;
      if (width > 0 && height > 0) {
        _aspect = width / height;
      }
      if (event['event'] == 'complete') {
        _playing = false;
        _positionMs = _durationMs;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    MediaChannel.videoDispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await MediaChannel.videoPause();
      setState(() => _playing = false);
    } else {
      if (_durationMs > 0 && _positionMs >= _durationMs) {
        await MediaChannel.videoSeek(0);
      }
      await MediaChannel.videoPlay();
      setState(() => _playing = true);
    }
  }

  Future<void> _skip(int ms) async {
    final next = (_positionMs + ms).clamp(0, _durationMs);
    await MediaChannel.videoSeek(next);
    setState(() => _positionMs = next);
  }

  Future<void> _toggleMute() async {
    final muted = !_muted;
    await MediaChannel.videoMute(muted: muted);
    setState(() => _muted = muted);
  }

  String _time(int ms) {
    final d = Duration(milliseconds: ms < 0 ? 0 : ms);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: _textureId == null
                  ? const CircularProgressIndicator()
                  : AspectRatio(
                      aspectRatio: _aspect,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ColoredBox(
                            color: Colors.black,
                            child: Texture(textureId: _textureId!),
                          ),
                          if (!_ready) const CircularProgressIndicator(),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(onTap: _ready ? _togglePlay : null),
                            ),
                          ),
                          if (_ready && !_playing)
                            const IgnorePointer(
                              child: Icon(
                                Icons.play_circle,
                                size: 72,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _durationMs == 0
                ? 0
                : _positionMs.clamp(0, _durationMs).toDouble(),
            max: (_durationMs == 0 ? 1 : _durationMs).toDouble(),
            onChangeStart: _ready ? (_) => setState(() => _seeking = true) : null,
            onChanged: _ready
                ? (value) => setState(() => _positionMs = value.toInt())
                : null,
            onChangeEnd: _ready
                ? (value) async {
                    await MediaChannel.videoSeek(value.toInt());
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _ready ? () => _skip(-10000) : null,
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
              ),
              IconButton(
                onPressed: _ready ? _togglePlay : null,
                icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
                iconSize: 56,
              ),
              IconButton(
                onPressed: _ready ? () => _skip(10000) : null,
                icon: const Icon(Icons.forward_10),
                iconSize: 32,
              ),
              IconButton(
                onPressed: _ready ? _toggleMute : null,
                icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
