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
                  onSelected: (_) =>
                      setState(() => _videoQuality = VideoQuality.low),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Medium"),
                  selected: _videoQuality == VideoQuality.medium,
                  onSelected: (_) =>
                      setState(() => _videoQuality = VideoQuality.medium),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("High"),
                  selected: _videoQuality == VideoQuality.high,
                  onSelected: (_) =>
                      setState(() => _videoQuality = VideoQuality.high),
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
        Text(
          widget.size,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
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
                      VideoSource(
                        path: widget.file.path,
                        type: VideoSourceType.file,
                      ),
                    );
                    setState(() => _isReady = true);
                  },
                ),
              ),

              if (_isReady)
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 58,
                    color: Colors.white,
                  ),
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
