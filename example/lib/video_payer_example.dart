



import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_compressor/media_compressor.dart';
import 'package:native_video_player/native_video_player.dart';

class VideoCompareScreen extends StatefulWidget {
  final File originalVideo;
  final File compressedVideo;
  final int originalSize;
  final int compressedSize;

  const VideoCompareScreen({
    super.key,
    required this.originalVideo,
    required this.compressedVideo,
    required this.originalSize,
    required this.compressedSize,
  });

  @override
  State<VideoCompareScreen> createState() => _VideoCompareScreenState();
}

class _VideoCompareScreenState extends State<VideoCompareScreen> {
  VideoQuality _videoQuality = VideoQuality.medium;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Comparison")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Quality Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Low"),
                  selected: _videoQuality == VideoQuality.low,
                  onSelected: (_) => setState(() => _videoQuality = VideoQuality.low),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Medium"),
                  selected: _videoQuality == VideoQuality.medium,
                  onSelected: (_) => setState(() => _videoQuality = VideoQuality.medium),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("High"),
                  selected: _videoQuality == VideoQuality.high,
                  onSelected: (_) => setState(() => _videoQuality = VideoQuality.high),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _VideoPlayerCard(
                      label: "Original",
                      file: widget.originalVideo,
                      size: _formatBytes(widget.originalSize),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _VideoPlayerCard(
                      label: "Compressed",
                      file: widget.compressedVideo,
                      size: _formatBytes(widget.compressedSize),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small reusable player widget
class _VideoPlayerCard extends StatefulWidget {
  final String label;
  final File file;
  final String size;

  const _VideoPlayerCard({
    required this.label,
    required this.file,
    required this.size,
  });

  @override
  State<_VideoPlayerCard> createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<_VideoPlayerCard> {
  NativeVideoPlayerController? _controller;
  bool _isReady = false;
  bool _isPlaying = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(widget.size, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 8),

        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: NativeVideoPlayerView(
                  onViewReady: (controller) async {
                    _controller = controller;
                    await _controller!.loadVideo(
                      VideoSource(path: widget.file.path, type: VideoSourceType.file),
                    );
                    setState(() => _isReady = true);
                  },
                ),
              ),

              if (_isReady)
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle,
                      size: 58, color: Colors.white),
                  onPressed: () {
                    if (_isPlaying) {
                      _controller?.pause();
                    } else {
                      _controller?.play();
                    }
                    setState(() => _isPlaying = !_isPlaying);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// import 'dart:developer';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:native_video_player/native_video_player.dart';

// class NativeVideoPlayerScreen extends StatefulWidget {
//   final String? videoPath; // nullable
//   const NativeVideoPlayerScreen({super.key, this.videoPath});
  
//   @override
//   State<NativeVideoPlayerScreen> createState() =>
//       _NativeVideoPlayerScreenState();
// }

// class _NativeVideoPlayerScreenState extends State<NativeVideoPlayerScreen> {
//   NativeVideoPlayerController? _controller;
//   bool _isPlaying = false;
//   bool _isReady = false;
//   double _volume = 1.0; // 0.0 to 1.0

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   Future<void> _loadVideo() async {
//     final path = widget.videoPath;
//     if (path == null) return;

//     final file = File(path);
//     if (!await file.exists()) {
//       log('Video file does not exist: $path');
//       return;
//     }

//     await _controller?.loadVideo(
//       VideoSource(
//         path: path,
//         type: VideoSourceType.file,
//       ),
//     );

//     setState(() {
//       _isReady = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.videoPath?.split('/').last ?? 'No Video')),
//       body: Column(
//         children: [
//           Expanded(
//             child: NativeVideoPlayerView(
//               onViewReady: (controller) {
//                 _controller = controller;
//                 _loadVideo();
//               },
//             ),
//           ),
//           if (_isReady)
//             Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Rewind 5 seconds
//                       IconButton(
//                         icon: const Icon(Icons.replay_5),
//                         onPressed: () {
//                           // _controller?.seekBy(Duration(seconds: -5));
//                         },
//                       ),
//                       // Play / Pause
//                       IconButton(
//                         icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
//                         onPressed: () {
//                           if (_isPlaying) {
//                             _controller?.pause();
//                           } else {
//                             _controller?.play();
//                           }
//                           setState(() => _isPlaying = !_isPlaying);
//                         },
//                       ),
//                       // Fast-forward 5 seconds
//                       IconButton(
//                         icon: const Icon(Icons.forward_5),
//                         onPressed: () {
//                           // _controller?.seekBy(Duration(seconds: 5));
//                         },
//                       ),
//                       // Stop
//                       IconButton(
//                         icon: const Icon(Icons.stop),
//                         onPressed: () {
//                           _controller?.seekTo(Duration.zero);
//                           _controller?.pause();
//                           setState(() => _isPlaying = false);
//                         },
//                       ),
//                     ],
//                   ),
//                   // Volume slider
//                   Row(
//                     children: [
//                       const Icon(Icons.volume_down),
//                       Expanded(
//                         child: Slider(
//                           value: _volume,
//                           onChanged: (value) {
//                             setState(() => _volume = value);
//                             _controller?.setVolume(value);
//                           },
//                           min: 0,
//                           max: 1,
//                         ),
//                       ),
//                       const Icon(Icons.volume_up),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
