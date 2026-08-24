import 'package:flutter/services.dart';

class MediaChannel {
  static const MethodChannel _methods = MethodChannel('assignment02/media');
  static const EventChannel _events = EventChannel('assignment02/media_events');

  static Stream<Map<dynamic, dynamic>> events() {
    return _events.receiveBroadcastStream().map(
      (event) => Map<dynamic, dynamic>.from(event as Map),
    );
  }

  static Future<Map<dynamic, dynamic>> videoInit(String asset) async {
    final result = await _methods.invokeMethod('videoInit', {'asset': asset});
    return Map<dynamic, dynamic>.from(result as Map);
  }

  static Future<void> videoPlay() {
    return _methods.invokeMethod('videoPlay');
  }

  static Future<void> videoPause() {
    return _methods.invokeMethod('videoPause');
  }

  static Future<void> videoSeek(int ms) {
    return _methods.invokeMethod('videoSeek', {'ms': ms});
  }

  static Future<void> videoMute({required bool muted}) {
    return _methods.invokeMethod('videoMute', {'muted': muted});
  }

  static Future<void> videoDispose() {
    return _methods.invokeMethod('videoDispose');
  }

  static Future<Map<dynamic, dynamic>> audioPlay(String asset) async {
    final result = await _methods.invokeMethod('audioPlay', {'asset': asset});
    return Map<dynamic, dynamic>.from(result as Map);
  }

  static Future<void> audioPause() {
    return _methods.invokeMethod('audioPause');
  }

  static Future<void> audioResume() {
    return _methods.invokeMethod('audioResume');
  }

  static Future<void> audioSeek(int ms) {
    return _methods.invokeMethod('audioSeek', {'ms': ms});
  }

  static Future<void> audioStop() {
    return _methods.invokeMethod('audioStop');
  }
}
