import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_record_poc/player_widget.dart';

class PlayerItemWidget extends StatefulWidget {
  final String title;
  final String path;
  final Future<bool> Function(String) onDelete;
  const PlayerItemWidget({
    super.key,
    required this.title,
    required this.path,
    required this.onDelete,
  });

  @override
  State<PlayerItemWidget> createState() => _PlayerItemWidgetState();
}

class _PlayerItemWidgetState extends State<PlayerItemWidget> {
  AudioPlayer? player;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    player?.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: {
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.allowBluetoothA2DP,
          },
        ),
      ),
    );
    player?.setSource(DeviceFileSource(widget.path));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 16,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(widget.title),
              ),
              IconButton(
                onPressed: () async {
                  setState(() => isDeleting = true);
                  final result = await widget.onDelete(widget.path);
                  if (result) {
                    await player?.dispose();
                    setState(() => player = null);
                    setState(() => isDeleting = false);
                  }
                },
                icon:
                    isDeleting
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.delete),
              ),
            ],
          ),
          if (player != null) PlayerWidget(player: player!),
          Divider(height: 24),
        ],
      ),
    );
  }
}
