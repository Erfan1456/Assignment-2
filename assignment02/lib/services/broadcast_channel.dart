import 'dart:async';

class AppBroadcast {
  AppBroadcast._();

  static final StreamController<String> _custom =
      StreamController<String>.broadcast();

  static Stream<String> get custom => _custom.stream;

  static void sendCustom(String message) {
    _custom.add(message);
  }
}
