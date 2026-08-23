import 'package:flutter/material.dart';

import 'custom_receiver_page.dart';

class CustomInputPage extends StatefulWidget {
  const CustomInputPage({super.key});

  @override
  State<CustomInputPage> createState() => _CustomInputPageState();
}

class _CustomInputPageState extends State<CustomInputPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _proceed() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomReceiverPage(message: _controller.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: _proceed, child: const Text('Proceed')),
          ],
        ),
      ),
    );
  }
}
