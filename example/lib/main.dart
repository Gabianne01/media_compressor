// ignore_for_file: unused_import

import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_compressor/media_compressor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_compressor_example/video_payer_example.dart';
import 'package:native_video_player/native_video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Compressor Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const CompressorDemo(),
    );
  }
}

class CompressorDemo extends StatefulWidget {
  const CompressorDemo({super.key});

  @override
  State<CompressorDemo> createState() => _CompressorDemoState();
}

class _CompressorDemoState extends State<CompressorDemo> {
  final ImagePicker _picker = ImagePicker();
  
  File? _originalFile;
  File? _compressedFile;
  int? _originalSize;
  int? _compressedSize;
  bool _isCompressing = false;
  double _progress = 0.0;
  String _selectedType = 'image'; // 'image' or 'video'
  
  // Quality settings
  int _imageQuality = 80;
  VideoQuality _videoQuality = VideoQuality.medium;

  Future<void> _pickFile() async {
    try {
      if (_selectedType == 'image') {
        final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
        if (file == null) return;
        
        final imageFile = File(file.path);
        final size = await imageFile.length();
        
        setState(() {
          _originalFile = imageFile;
          _originalSize = size;
          _compressedFile = null;
          _compressedSize = null;
          _progress = 0.0;
        });
        
        await _compressImage();
      } else {
        final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
        if (file == null) return;
        
        final videoFile = File(file.path);
        final size = await videoFile.length();
        
        setState(() {
          _originalFile = videoFile;
          _originalSize = size;
          _compressedFile = null;
          _compressedSize = null;
          _progress = 0.0;
        });
        
        await _compressVideo();
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _compressImage() async {
    if (_originalFile == null) return;

    setState(() {
      _isCompressing = true;
      _progress = 0.0;
    });

    try {
      // Simulate progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() => _progress = i / 100);
        }
      }

      final result = await MediaCompressor.compressImage(
        ImageCompressionConfig(
          path: _originalFile!.path,
          quality: _imageQuality,
          maxWidth: 1920,
          maxHeight: 1080,
        ),
      );

      if (result.isSuccess) {
        final compressedFile = File(result.path!);
        final compressedSize = await compressedFile.length();

        setState(() {
          _compressedFile = compressedFile;
          _compressedSize = compressedSize;
          _progress = 1.0;
          _isCompressing = false;
        });
      } else {
        throw Exception(result.error?.message ?? 'Compression failed');
      }
    } catch (e) {
      setState(() => _isCompressing = false);
      _showError('Compression failed: $e');
    }
  }

  Future<void> _compressVideo() async {
    if (_originalFile == null) return;

    setState(() {
      _isCompressing = true;
      _progress = 0.0;
    });

    try {
      // Simulate progress
      _simulateProgress();

      final result = await MediaCompressor.compressVideo(
        VideoCompressionConfig(
          path: _originalFile!.path,
          quality: _videoQuality,
        ),
      );

      if (result.isSuccess) {
        final compressedFile = File(result.path!);
        final compressedSize = await compressedFile.length();

        setState(() {
          _compressedFile = compressedFile;
          _compressedSize = compressedSize;
          _progress = 1.0;
          _isCompressing = false;
        });


        if (mounted) {
 
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VideoCompareScreen(
        originalVideo: _originalFile!,
        compressedVideo: compressedFile,
        originalSize: _originalSize!,
        compressedSize: compressedSize,
      ),
    ),
  );
}

      } else {
        throw Exception(result.error?.message ?? 'Compression failed');
      }
    } catch (e) {
      setState(() => _isCompressing = false);
      _showError('Compression failed: $e');
    }
  }

  void _simulateProgress() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_isCompressing && mounted && _progress < 0.9) {
        setState(() => _progress += 0.05);
        _simulateProgress();
      }
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _ = _originalSize != null && _compressedSize != null
        ? ((1 - (_compressedSize! / _originalSize!)) * 100).toInt()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Compressor'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type selector
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Image'),
                    selected: _selectedType == 'image',
                    onSelected: (_) => setState(() {
                      _selectedType = 'image';
                      _originalFile = null;
                      _compressedFile = null;
                      _originalSize = null;
                      _compressedSize = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Video'),
                    selected: _selectedType == 'video',
                    onSelected: (_) => setState(() {
                      _selectedType = 'video';
                      _originalFile = null;
                      _compressedFile = null;
                      _originalSize = null;
                      _compressedSize = null;
                    }),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // Pick file button
            ElevatedButton.icon(
              onPressed: _isCompressing ? null : _pickFile,
              icon: Icon(_selectedType == 'image' ? Icons.image : Icons.video_library),
              label: Text('Select ${_selectedType == 'image' ? 'Image' : 'Video'}'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            // Quality slider
            if (_selectedType == 'image') ...[
              const Text('Image Quality', style: TextStyle(fontWeight: FontWeight.w500)),
              Row(
                children: [
                  const Text('Low', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _imageQuality.toDouble(),
                      min: 10,
                      max: 100,
                      divisions: 18,
                      label: '$_imageQuality%',
                      onChanged: _isCompressing ? null : (value) {
                        setState(() => _imageQuality = value.toInt());
                      },
                      onChangeEnd: (_) {
                        if (_originalFile != null) _compressImage();
                      },
                    ),
                  ),
                  const Text('High', style: TextStyle(fontSize: 12)),
                ],
              ),
            ] else ...[
              const Text('Video Quality', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SegmentedButton<VideoQuality>(
                segments: const [
                  ButtonSegment(value: VideoQuality.low, label: Text('Low')),
                  ButtonSegment(value: VideoQuality.medium, label: Text('Medium')),
                  ButtonSegment(value: VideoQuality.high, label: Text('High')),
                ],
                selected: {_videoQuality},
                onSelectionChanged: _isCompressing ? null : (Set<VideoQuality> newSelection) {
                  setState(() => _videoQuality = newSelection.first);
                  if (_originalFile != null) _compressVideo();
                },
              ),
            ],

            if (_isCompressing || _originalFile != null) ...[
              // const SizedBox(height: 30),

              // Progress indicator
              if (_isCompressing) ...[
                const Text(
                  'Compressing...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 30),
              ],

              // Size comparison
              if (_originalSize != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildSizeCard(
                        'Before',
                        _formatBytes(_originalSize!),
                        Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSizeCard(
                        'After',
                        _compressedSize != null
                            ? _formatBytes(_compressedSize!)
                            : '...',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
   
              ],

              ],

              // Preview
              if (_selectedType == 'image') ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Original',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                             height: 400,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: _originalFile != null
                                    ? Image.file(_originalFile!, fit: BoxFit.cover)
                                    : Container(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Compressed',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                                  height: 400,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: _compressedFile != null
                                    ? Image.file(_compressedFile!, fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: _isCompressing
                                            ? const Center(child: CircularProgressIndicator())
                                            : null,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

             
            ],
          
        ),
      ),
    );
  }

  Widget _buildSizeCard(String label, String size, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
  
        borderRadius: BorderRadius.circular(12),
  
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
            
            ),
          ),
          const SizedBox(height: 4),
          Text(
            size,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
    
            ),
          ),
        ],
      ),
    );
  }

}

