import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class vidodeteksi extends StatefulWidget {
  final String videoPath;
  final String data;

  const vidodeteksi({Key? key, required this.videoPath, required this.data})
      : super(key: key);

  @override
  State<vidodeteksi> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<vidodeteksi> {
  late VideoPlayerController _videoController;
  late FlutterVision _vision;
  List<Map<String, dynamic>> _yoloResults = [];
  bool _isLoaded = false;
  bool _isDetecting = false;
  Map<String, int> _objectCounts = {};
  FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset("assets/images/jalan.mp4");

    await _videoController.initialize();

    _vision = FlutterVision();
    await _vision.loadYoloModel(
      labels: 'assets/label.txt',
      modelPath: 'assets/yolov8s_float32.tflite',
      modelVersion: "yolov8",
      numThreads: 1,
      useGpu: true,
    );

    setState(() {
      _isLoaded = true;
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _vision.closeYoloModel();
    super.dispose();
  }

  Future<void> _startDetection() async {
    setState(() {
      _isDetecting = true;
    });

    await _videoController.play();
    _videoController.addListener(_processVideoFrame);
  }

  void _processVideoFrame() async {
    final frameInfo = await _videoController.position;

    if (_isDetecting) {
      Uint8List? frameBytes = await _extractFrame(frameInfo!);

      if (frameBytes != null) {
        final result = await _vision.yoloOnFrame(
          bytesList: [frameBytes],
          imageHeight: _videoController.value.size!.height.toInt(),
          imageWidth: _videoController.value.size!.width.toInt(),
          iouThreshold: 0.4,
          confThreshold: 0.4,
          classThreshold: 0.5,
        );

        if (result.isNotEmpty) {
          setState(() {
            _yoloResults = result;
            _updateObjectCounts();
            _sendDetectionResultsToAPI();
          });
        }
      }
    }
  }

  Future<Uint8List?> _extractFrame(Duration frameInfo) async {
    try {
      final outputPath = await _getFrameOutputPath();
      final command =
          '-i ${"assets/images/jalan.mp4"} -ss ${frameInfo.inSeconds} -frames:v 1 $outputPath';
      await _flutterFFmpeg.execute(command);

      return await _readFrame(outputPath);
    } catch (e) {
      print('Error extracting frame: $e');
      return null;
    }
  }

  Future<String> _getFrameOutputPath() async {
    final directory = await Directory.systemTemp.createTemp();
    return '${directory.path}/frame.jpg';
  }

  Future<Uint8List?> _readFrame(String framePath) async {
    try {
      final file = File(framePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        print('Frame file not found.');
        return null;
      }
    } catch (e) {
      print('Error reading frame: $e');
      return null;
    }
  }

  void _updateObjectCounts() {
    _objectCounts.clear();
    for (var result in _yoloResults) {
      String tag = result['tag'];
      if (_objectCounts.containsKey(tag)) {
        _objectCounts[tag] = _objectCounts[tag]! + 1;
      } else {
        _objectCounts[tag] = 1;
      }
    }
  }

  Future<void> _sendDetectionResultsToAPI() async {
    final url = Uri.parse('https://example.com/save-detection');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'lokasi': widget.data,
        'timestamp': DateTime.now().toIso8601String(),
        'counts': _objectCounts,
      }),
    );

    if (response.statusCode == 200) {
      print('Detection results sent successfully');
    } else {
      print('Failed to send detection results: ${response.body}');
    }
  }

  Future<void> _stopDetection() async {
    setState(() {
      _isDetecting = false;
      _yoloResults.clear();
      _objectCounts.clear();
    });

    await _videoController.pause();
    _videoController.removeListener(_processVideoFrame);
  }

  List<Widget> _displayBoxesAroundRecognizedObjects(Size screen) {
    if (_yoloResults.isEmpty) return [];

    double factorX = screen.width / _videoController.value.size!.width;
    double factorY = screen.height / _videoController.value.size!.height;

    return _yoloResults.map((result) {
      double objectX = result["box"][0] * factorX;
      double objectY = result["box"][1] * factorY;
      double objectWidth = (result["box"][2] - result["box"][0]) * factorX;
      double objectHeight = (result["box"][3] - result["box"][1]) * factorY;

      return Positioned(
        left: objectX,
        top: objectY,
        width: objectWidth,
        height: objectHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(1)}%",
            style: TextStyle(
              background: Paint()..color = Colors.green,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _displayObjectCounts() {
    return Positioned(
      top: 100,
      left: 10,
      child: Container(
        color: Colors.black54,
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _objectCounts.entries.map((entry) {
            return Text(
              "${entry.key}: ${entry.value}",
              style: TextStyle(color: Colors.white, fontSize: 18),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if (!_isLoaded) {
      return Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _videoController.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                )
              : Container(),
          ..._displayBoxesAroundRecognizedObjects(size),
          _displayObjectCounts(),
          Positioned(
            bottom: 75,
            width: MediaQuery.of(context).size.width,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 5,
                  color: Colors.white,
                  style: BorderStyle.solid,
                ),
              ),
              child: _isDetecting
                  ? IconButton(
                      onPressed: () async {
                        await _stopDetection();
                      },
                      icon: const Icon(
                        Icons.stop,
                        color: Colors.red,
                      ),
                      iconSize: 50,
                    )
                  : IconButton(
                      onPressed: () async {
                        await _startDetection();
                      },
                      icon: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                      ),
                      iconSize: 50,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
