import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/broadcast_channel.dart';

class BatteryReceiverPage extends StatefulWidget {
  const BatteryReceiverPage({super.key});

  @override
  State<BatteryReceiverPage> createState() => _BatteryReceiverPageState();
}

class _BatteryReceiverPageState extends State<BatteryReceiverPage> {
  StreamSubscription<int>? _subscription;
  int? _percent;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = BroadcastChannel.batteryPercents().listen(
      (percent) => setState(() => _percent = percent),
      onError: (Object error) {
        setState(() {
          _error = error is MissingPluginException
              ? 'Battery broadcast receiver is available on Android only.'
              : error.toString();
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _error ??
        (_percent == null
            ? 'Waiting for battery broadcast...'
            : 'Battery percentage: $_percent%');

    return Scaffold(
      appBar: AppBar(title: const Text('App'), centerTitle: true),
      body: Center(child: Text(body, textAlign: TextAlign.center)),
    );
  }
}
