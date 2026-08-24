import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

class BatteryReceiverPage extends StatefulWidget {
  const BatteryReceiverPage({super.key});

  @override
  State<BatteryReceiverPage> createState() => _BatteryReceiverPageState();
}

class _BatteryReceiverPageState extends State<BatteryReceiverPage> {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _subscription;
  Timer? _timer;
  int? _percent;

  @override
  void initState() {
    super.initState();
    _readLevel();
    _subscription = _battery.onBatteryStateChanged.listen((_) => _readLevel());
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _readLevel());
  }

  Future<void> _readLevel() async {
    final percent = await _battery.batteryLevel;
    if (mounted) {
      setState(() => _percent = percent);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _percent == null
        ? 'Waiting for battery broadcast...'
        : 'Battery percentage: $_percent%';

    return Scaffold(
      appBar: AppBar(title: const Text('App'), centerTitle: true),
      body: Center(child: Text(body, textAlign: TextAlign.center)),
    );
  }
}
