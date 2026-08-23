import 'package:flutter/material.dart';

import 'battery_receiver_page.dart';
import 'custom_input_page.dart';

class BroadcastSelectPage extends StatefulWidget {
  const BroadcastSelectPage({super.key});

  @override
  State<BroadcastSelectPage> createState() => _BroadcastSelectPageState();
}

class _BroadcastSelectPageState extends State<BroadcastSelectPage> {
  static const String customOption = 'Custom broadcast receiver';
  static const String batteryOption = 'System battery notification receiver';

  String _selected = customOption;

  void _proceed() {
    if (_selected == customOption) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const CustomInputPage()));
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BatteryReceiverPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select a broadcast type'),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _selected,
              items: const [
                DropdownMenuItem(
                  value: customOption,
                  child: Text(customOption),
                ),
                DropdownMenuItem(
                  value: batteryOption,
                  child: Text(batteryOption),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selected = value);
                }
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: _proceed, child: const Text('Proceed')),
          ],
        ),
      ),
    );
  }
}
