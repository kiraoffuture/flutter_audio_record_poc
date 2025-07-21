import 'dart:io';
import 'dart:async';
import 'package:audio_record_poc/player_item_widget.dart';
import 'package:audio_record_poc/utils.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class _Constants {
  static const String musicPath = 'lib/assets/audio/music.mp3';
  static const String musicName = 'music.mp3';
  static const String vocalPath = 'lib/assets/audio/vocal.mp3';
  static const String vocalName = 'vocal.mp3';
  static const String recordName = 'record.m4a';
}

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
  final _audioRecorder = AudioRecorder();
  List<File> _files = [];
  bool _isMixingSample = false;
  bool _isMixingRecord = false;
  bool _isDeletingAllFiles = false;
  bool _isPreparingSampleAudioFiles = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();

    displayFiles();
  }

  Future<void> _startRecording() async {
    setState(() => _isRecording = true);
    if (await _audioRecorder.hasPermission()) {
      final temporaryDirectory = await getTemporaryDirectory();
      final outputPath = '${temporaryDirectory.path}/record.m4a';
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      await outputFile.create(recursive: true);
      final inputDevices = await _audioRecorder.listInputDevices();
      final recordConfig = RecordConfig(
        encoder: AudioEncoder.flac,
        numChannels: 2,
        device: inputDevices[0],
      );
      await _audioRecorder.start(recordConfig, path: outputFile.path);
    }
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    await _audioRecorder.dispose();
    setState(() => _isRecording = false);
    displayFiles();
  }

  Future<void> mixSampleAudioFiles() async {
    final temporaryDirectory = await getTemporaryDirectory();
    final pathMusic = '${temporaryDirectory.path}/${_Constants.musicName}';
    final pathVocal = '${temporaryDirectory.path}/${_Constants.vocalName}';
    final pathMixed = '${temporaryDirectory.path}/sample_output_mix.mp3';
    setState(() => _isMixingSample = true);
    await mixAudio(pathMusic, pathVocal, pathMixed);
    setState(() => _isMixingSample = false);
  }

  Future<void> mixAudioWithRecord() async {
    final temporaryDirectory = await getTemporaryDirectory();
    final pathMusic = '${temporaryDirectory.path}/${_Constants.musicName}';
    final pathRecord = '${temporaryDirectory.path}/${_Constants.recordName}';
    final pathMixed = '${temporaryDirectory.path}/record_output_mix.mp3';
    setState(() => _isMixingRecord = true);
    await mixAudio(pathMusic, pathRecord, pathMixed);
    setState(() => _isMixingRecord = false);
  }

  Future<void> mixAudio(
    String firstPath,
    String secondPath,
    String outputPath,
  ) async {
    // Step 1: Mix
    await FFmpegKit.execute(
      '-i $firstPath -i $secondPath -filter_complex amix=inputs=2:duration=longest $outputPath',
    );

    // Step 2: Trim
    // await FFmpegKit.execute('-i $pathMixed -t ${266 / 2} $pathFinal');

    displayFiles();
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

  Future<void> prepareSampleAudioFiles() async {
    final temporaryDirectory = await getTemporaryDirectory();
    setState(() => _isPreparingSampleAudioFiles = true);
    await Utils.copyAssetToFile(
      temporaryDirectory.path,
      _Constants.musicPath,
      _Constants.musicName,
    );
    await Utils.copyAssetToFile(
      temporaryDirectory.path,
      _Constants.vocalPath,
      _Constants.vocalName,
    );
    Future.delayed(const Duration(seconds: 2), () async {
      await displayFiles();
      setState(() => _isPreparingSampleAudioFiles = false);
    });
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
                      onPressed:
                          _isPreparingSampleAudioFiles
                              ? null
                              : prepareSampleAudioFiles,
                      child:
                          _isPreparingSampleAudioFiles
                              ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Prepare sample'),
                    ),
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _isMixingSample ? null : mixSampleAudioFiles,
                      child:
                          _isMixingSample
                              ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Mix sample'),
                    ),
                    ElevatedButton(
                      onPressed: _isMixingRecord ? null : mixAudioWithRecord,
                      child:
                          _isMixingRecord
                              ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Mix record'),
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
