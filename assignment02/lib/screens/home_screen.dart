import 'package:flutter/material.dart';

import 'audio_page.dart';
import 'broadcast/broadcast_select_page.dart';
import 'image_scale_page.dart';
import 'video_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<String> _titles = [
    'Broadcast Receiver',
    'Image Scale',
    'Video',
    'Audio',
  ];

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).pop();
  }

  Widget _currentPage() {
    switch (_selectedIndex) {
      case 0:
        return const BroadcastSelectPage();
      case 1:
        return const ImageScalePage();
      case 2:
        return const VideoPage();
      case 3:
        return const AudioPage();
      default:
        return const BroadcastSelectPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App'), centerTitle: true),
      drawer: Drawer(
        child: ListView(
          children: [
            for (var i = 0; i < _titles.length; i++)
              ListTile(
                title: Text(_titles[i]),
                onTap: () => _selectPage(i),
              ),
          ],
        ),
      ),
      body: _currentPage(),
    );
  }
}
