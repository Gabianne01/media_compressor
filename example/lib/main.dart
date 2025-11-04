import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:media_compressor/media_compressor.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Compressor Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ImageCompressorDemo(),
    );
  }
}

class ImageCompressorDemo extends StatefulWidget {
  const ImageCompressorDemo({super.key});

  @override
  State<ImageCompressorDemo> createState() => _ImageCompressorDemoState();
}

class _ImageCompressorDemoState extends State<ImageCompressorDemo> {
  final _compressor = MediaCompressor();
  final _imagePicker = ImagePicker();
  
  File? _originalImage;
  File? _compressedImage;
  double _quality = 70;
  bool _isCompressing = false;
  String? _compressionStats;

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _originalImage = File(pickedFile.path);
        _compressedImage = null;
        _compressionStats = null;
      });
      await _compressImage();
    }
  }

  Future<void> _compressImage() async {
    if (_originalImage == null) return;

    setState(() {
      _isCompressing = true;
    });

    try {
      final result = await _compressor.compressImageWithOptions(
        path: _originalImage!.path,
        quality: _quality.round(),
      );

      if (result != null) {
        setState(() {
          _compressedImage = File(result['path'] as String);
          final originalSize = result['originalSize'] as int;
          final compressedSize = result['compressedSize'] as int;
          final ratio = result['compressionRatio'] as double;

          _compressionStats = 
            'Original: ${(originalSize / 1024).toStringAsFixed(2)} KB\n'
            'Compressed: ${(compressedSize / 1024).toStringAsFixed(2)} KB\n'
            'Ratio: ${(ratio * 100).toStringAsFixed(1)}%';
        });
      }
    } catch (e) {
      log('Compression error: $e'); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isCompressing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Compressor Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Select Image'),
            ),
            const SizedBox(height: 16),
            if (_originalImage != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Original'),
                        const SizedBox(height: 8),
                        Image.file(
                          _originalImage!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Compressed'),
                        const SizedBox(height: 8),
                        if (_isCompressing)
                          const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_compressedImage != null)
                          Image.file(
                            _compressedImage!,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Quality: ${_quality.round()}%',
                textAlign: TextAlign.center,
              ),
              Slider(
                value: _quality,
                min: 0,
                max: 100,
                divisions: 100,
                label: _quality.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _quality = value;
                  });
                },
                onChangeEnd: (value) {
                  _compressImage();
                },
              ),
              if (_compressionStats != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _compressionStats!,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
