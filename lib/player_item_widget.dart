import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_record_poc/player_widget.dart';

class PlayerItemWidget extends StatefulWidget {
  final String title;
  final String path;
  const PlayerItemWidget({super.key, required this.title, required this.path});

  @override
  State<PlayerItemWidget> createState() => _PlayerItemWidgetState();
}

class _PlayerItemWidgetState extends State<PlayerItemWidget> {
  AudioPlayer? player;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    player?.setSource(DeviceFileSource(widget.path));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 16,
        children: [
          Text(widget.title),
          if (player != null) PlayerWidget(player: player!),
          Divider(height: 24),
        ],
      ),
    );
  }
}
