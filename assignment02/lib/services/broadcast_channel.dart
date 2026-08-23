import 'package:flutter/services.dart';

class BroadcastChannel {
  static const EventChannel _customEvents = EventChannel(
    'assignment02/custom_broadcast',
  );
  static const EventChannel _batteryEvents = EventChannel(
    'assignment02/battery_broadcast',
  );

  static Stream<String> customBroadcasts([String? message]) {
    return _customEvents
        .receiveBroadcastStream(message)
        .map((event) => event.toString());
  }

  static Stream<int> batteryPercents() {
    return _batteryEvents.receiveBroadcastStream().map((event) => event as int);
  }
}
