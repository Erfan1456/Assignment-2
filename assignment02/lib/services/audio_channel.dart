import 'package:flutter/services.dart';

class AudioChannel {
  static const MethodChannel _channel = MethodChannel('assignment02/audio');

  static Future<void> play(String url) {
    return _channel.invokeMethod('play', {'url': url});
  }

  static Future<void> pause() {
    return _channel.invokeMethod('pause');
  }

  static Future<void> resume() {
    return _channel.invokeMethod('resume');
  }

  static Future<void> stop() {
    return _channel.invokeMethod('stop');
  }
}
