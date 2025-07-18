import 'dart:io';
import 'dart:async';
import 'package:audio_record_poc/player_item_widget.dart';
import 'package:audio_record_poc/utils.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<File> _files = [];
  bool _isMixing = false;
  bool _isDeletingAllFiles = false;

  @override
  void initState() {
    super.initState();

    displayFiles();
  }

  Future<void> mixAudio() async {
    setState(() => _isMixing = true);
    final temporaryDirectory = await getTemporaryDirectory();
    final musicFile = await Utils.copyAssetToFile(
      temporaryDirectory.path,
      'lib/assets/audio/music.mp3',
      'music.mp3',
    );
    final vocalFile = await Utils.copyAssetToFile(
      temporaryDirectory.path,
      'lib/assets/audio/vocal.mp3',
      'vocal.mp3',
    );
    final output = File('${temporaryDirectory.path}/output_mix.mp3');

    final pathMusic = musicFile.path;
    final pathVocal = vocalFile.path;
    final pathMixed = output.path;

    // Step 1: Mix
    await FFmpegKit.execute(
      '-i $pathMusic -i $pathVocal -filter_complex amix=inputs=2:duration=longest $pathMixed',
    );

    // Step 2: Trim
    // await FFmpegKit.execute('-i $pathMixed -t ${266 / 2} $pathFinal');

    displayFiles();
    setState(() => _isMixing = false);
  }

  Future<void> displayFiles() async {
    final temporaryDirectory = await getTemporaryDirectory();
    final files = temporaryDirectory.listSync();
    setState(
      () =>
          _files =
              files
                  .map((e) => File(e.path))
                  .where((e) => e.path.contains('mp3'))
                  .toList(),
    );
  }

  void deleteFile(File file) {
    file.delete();
    setState(() => _files.remove(file));
  }

  Future<void> deleteAllFiles() async {
    setState(() => _isDeletingAllFiles = true);
    await Future.wait(_files.map((e) => e.delete()));
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _files.clear();
        _isDeletingAllFiles = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Mix POC')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _isDeletingAllFiles ? null : deleteAllFiles,
                      child:
                          _isDeletingAllFiles
                              ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Delete all files'),
                    ),
                    ElevatedButton(
                      onPressed: _isMixing ? null : mixAudio,
                      child:
                          _isMixing
                              ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Mix audio'),
                    ),
                  ],
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('File list', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ),
              ..._files.map(
                (e) => PlayerItemWidget(
                  title: e.uri.pathSegments.last,
                  path: e.path,
                ),
              ),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
