import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/broadcast_channel.dart';

class CustomReceiverPage extends StatefulWidget {
  const CustomReceiverPage({super.key, required this.message});

  final String message;

  @override
  State<CustomReceiverPage> createState() => _CustomReceiverPageState();
}

class _CustomReceiverPageState extends State<CustomReceiverPage> {
  StreamSubscription<String>? _subscription;
  String _received = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = BroadcastChannel.customBroadcasts(widget.message).listen(
      (message) => setState(() => _received = message),
      onError: (Object error) {
        setState(() {
          _error = error is MissingPluginException
              ? 'Custom broadcast receiver is available on Android only.'
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
    return Scaffold(
      appBar: AppBar(title: const Text('App'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error ??
                (_received.isEmpty
                    ? 'Waiting for custom broadcast...'
                    : _received),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
