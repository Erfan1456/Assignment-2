import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  static const String _videoAsset = 'assets/media/sample_video.mp4';

  VideoPlayerController? _controller;
  bool _ready = false;
  bool _seeking = false;
  bool _muted = false;
  Duration _position = Duration.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final controller = VideoPlayerController.asset(_videoAsset);
    _controller = controller;
    controller.addListener(_onTick);
    try {
      await controller.initialize();
      await controller.play();
      if (mounted) {
        setState(() => _ready = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not play video');
      }
    }
  }

  void _onTick() {
    final controller = _controller;
    if (!mounted || controller == null || !controller.value.isInitialized) {
      return;
    }
    if (!_seeking) {
      setState(() => _position = controller.value.position);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  VideoPlayerController get _player => _controller!;

  bool get _playing => _player.value.isPlaying;

  Duration get _duration => _player.value.duration;

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      if (_duration.inMilliseconds > 0 &&
          _position >= _duration - const Duration(milliseconds: 400)) {
        await _player.seekTo(Duration.zero);
      }
      await _player.play();
    }
    setState(() {});
  }

  Future<void> _skip(int ms) async {
    final next = _position + Duration(milliseconds: ms);
    final clamped = next < Duration.zero
        ? Duration.zero
        : (next > _duration ? _duration : next);
    await _player.seekTo(clamped);
    setState(() => _position = clamped);
  }

  Future<void> _toggleMute() async {
    final muted = !_muted;
    await _player.setVolume(muted ? 0 : 1);
    setState(() => _muted = muted);
  }

  String _time(Duration d) {
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
    if (!_ready || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final durationMs = _duration.inMilliseconds;
    final positionMs = _position.inMilliseconds.clamp(0, durationMs);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _player.value.aspectRatio == 0
                    ? 16 / 9
                    : _player.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ColoredBox(
                      color: Colors.black,
                      child: VideoPlayer(_player),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(onTap: _togglePlay),
                      ),
                    ),
                    if (!_playing)
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
            value: durationMs == 0 ? 0 : positionMs.toDouble(),
            max: (durationMs == 0 ? 1 : durationMs).toDouble(),
            onChangeStart: (_) => setState(() => _seeking = true),
            onChanged: (value) {
              setState(() => _position = Duration(milliseconds: value.toInt()));
            },
            onChangeEnd: (value) async {
              await _player.seekTo(Duration(milliseconds: value.toInt()));
              setState(() => _seeking = false);
            },
          ),
          Row(
            children: [
              Text(_time(_position)),
              const Spacer(),
              Text(_time(_duration)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _skip(-10000),
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
              ),
              IconButton(
                onPressed: _togglePlay,
                icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
                iconSize: 56,
              ),
              IconButton(
                onPressed: () => _skip(10000),
                icon: const Icon(Icons.forward_10),
                iconSize: 32,
              ),
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
