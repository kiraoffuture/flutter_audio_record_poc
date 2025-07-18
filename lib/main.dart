import 'dart:io';
import 'dart:async';
import 'package:audio_record_poc/player_item_widget.dart';
import 'package:audio_record_poc/utils.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

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
  final audioRecorder = AudioRecorder();
  List<File> _files = [];
  bool _isMixing = false;
  bool _isDeletingAllFiles = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();

    displayFiles();
  }

  Future<void> _startRecording() async {
    setState(() => _isRecording = true);
    if (await audioRecorder.hasPermission()) {
      final temporaryDirectory = await getTemporaryDirectory();
      final outputPath = '${temporaryDirectory.path}/record.m4a';
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      await outputFile.create(recursive: true);
      await audioRecorder.start(const RecordConfig(), path: outputFile.path);
    }
  }

  Future<void> _stopRecording() async {
    await audioRecorder.stop();
    await audioRecorder.dispose();
    setState(() => _isRecording = false);
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
                  .where(
                    (e) => e.path.contains('mp3') || e.path.contains('m4a'),
                  )
                  .toList(),
    );
  }

  Future<bool> deleteFile(String path) async {
    final file = File(path);
    await file.delete();
    setState(() => _files.removeWhere((e) => e.path == path));
    displayFiles();
    return true;
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
              SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: _isRecording ? null : _startRecording,
                      child:
                          _isRecording
                              ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Start recording'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: !_isRecording ? null : _stopRecording,
                      child: const Text('Stop recording'),
                    ),
                  ),
                ],
              ),
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
                  onDelete: deleteFile,
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
