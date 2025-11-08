import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:media_compressor/media_compressor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_compressor_example/video_payer_example.dart';

void main() {
    WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Compressor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      
      ),
      home: const MediaCompressorDemo(),
    );
  }
}

class MediaCompressorDemo extends StatefulWidget {
  const MediaCompressorDemo({super.key});

  @override
  State<MediaCompressorDemo> createState() => _MediaCompressorDemoState();
}

class _MediaCompressorDemoState extends State<MediaCompressorDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.compress,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Media Compressor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Reduce file size without losing quality',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Custom Tab Bar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.white,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image),
                              SizedBox(width: 8),
                              Text('Images'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library),
                              SizedBox(width: 8),
                              Text('Videos'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ImageCompressorTab(picker: _picker),
                  VideoCompressorTab(picker: _picker),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// IMAGE COMPRESSOR TAB
// ============================================================================

class ImageCompressorTab extends StatefulWidget {
  final ImagePicker picker;

  const ImageCompressorTab({super.key, required this.picker});

  @override
  State<ImageCompressorTab> createState() => _ImageCompressorTabState();
}

class _ImageCompressorTabState extends State<ImageCompressorTab> {
  File? _originalImage;
  File? _compressedImage;
  int _quality = 80;
  int _maxWidth = 1920;
  int _maxHeight = 1080;
  bool _isCompressing = false;
  String? _statusMessage;
  int? _originalSize;
  int? _compressedSize;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await widget.picker.pickImage(source: source);
      if (image == null) return;

      final file = File(image.path);
      final size = await file.length();

      setState(() {
        _originalImage = file;
        _originalSize = size;
        _compressedImage = null;
        _compressedSize = null;
        _statusMessage = null;
      });

      await _compressImage();
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _compressImage() async {
    if (_originalImage == null) return;

    setState(() {
      _isCompressing = true;
      _statusMessage = 'Compressing...';
    });

    try {
      final result = await MediaCompressor.compressImage(
        ImageCompressionConfig(
          path: _originalImage!.path,
          quality: _quality,
          maxWidth: _maxWidth,
          maxHeight: _maxHeight,
        ),
      );

      if (result.isSuccess) {
        final compressedFile = File(result.path!);
        final compressedSize = await compressedFile.length();

        setState(() {
          _compressedImage = compressedFile;
          _compressedSize = compressedSize;
          _statusMessage = 'Compression complete!';
          _isCompressing = false;
        });
      } else {
        setState(() {
          _statusMessage = 'Error: ${result.error!.message}';
          _isCompressing = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isCompressing = false;
      });
    }
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedPercentage = _originalSize != null && _compressedSize != null
        ? ((1 - (_compressedSize! / _originalSize!)) * 100).toInt()
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pick Image Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onPressed:
                      _isCompressing ? null : () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onPressed:
                      _isCompressing ? null : () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Card
          if (_originalSize != null || _compressedSize != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Original',
                          _formatBytes(_originalSize ?? 0),
                          Icons.image_outlined,
                          Colors.blue,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatItem(
                          'Compressed',
                          _compressedSize != null
                              ? _formatBytes(_compressedSize!)
                              : '-',
                          Icons.compress,
                          Colors.green,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatItem(
                          'Saved',
                          _compressedSize != null ? '$savedPercentage%' : '-',
                          Icons.trending_down,
                          Colors.orange,
                        ),
                      ],
                    ),
                    if (_compressedSize != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 1 - (_compressedSize! / _originalSize!),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            savedPercentage > 50 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compression Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSlider(
                    'Quality',
                    _quality,
                    0,
                    100,
                    '%',
                    Icons.high_quality,
                    (value) => setState(() => _quality = value.toInt()),
                    () {
                      if (_originalImage != null) _compressImage();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSlider(
                    'Max Width',
                    _maxWidth,
                    480,
                    3840,
                    'px',
                    Icons.width_normal,
                    (value) => setState(() => _maxWidth = value.toInt()),
                    () {
                      if (_originalImage != null) _compressImage();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSlider(
                    'Max Height',
                    _maxHeight,
                    480,
                    2160,
                    'px',
                    Icons.height,
                    (value) => setState(() => _maxHeight = value.toInt()),
                    () {
                      if (_originalImage != null) _compressImage();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Preview Card
          if (_originalImage != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImagePreview(
                            'Original',
                            _originalImage!,
                            Icons.image,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isCompressing
                              ? _buildLoadingPreview()
                              : _compressedImage != null
                                  ? _buildImagePreview(
                                      'Compressed',
                                      _compressedImage!,
                                      Icons.compress,
                                    )
                                  : _buildEmptyPreview(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    int value,
    double min,
    double max,
    String unit,
    IconData icon,
    ValueChanged<double> onChanged,
    VoidCallback onChangeEnd,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value$unit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: ((max - min) / 10).toInt(),
          onChanged: onChanged,
          onChangeEnd: (_) => onChangeEnd(),
        ),
      ],
    );
  }

  Widget _buildImagePreview(String label, File file, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.file(
              file,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.hourglass_empty, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'Processing',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: Colors.grey.shade100,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.compress, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'Compressed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: Colors.grey.shade100,
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// VIDEO COMPRESSOR TAB (WITHOUT VIDEO PLAYER)
// ============================================================================

class VideoCompressorTab extends StatefulWidget {
  final ImagePicker picker;

  const VideoCompressorTab({super.key, required this.picker});

  @override
  State<VideoCompressorTab> createState() => _VideoCompressorTabState();
}

class _VideoCompressorTabState extends State<VideoCompressorTab> {
  File? _originalVideo;
  File? _compressedVideo;
  VideoQuality _quality = VideoQuality.medium;
  bool _isCompressing = false;
  String? _statusMessage;
  int? _originalSize;
  int? _compressedSize;
  int? _compressionTime;

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await widget.picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) return;

      final file = File(video.path);
      final size = await file.length();

      setState(() {
        _originalVideo = file;
        _originalSize = size;
        _compressedVideo = null;
        _compressedSize = null;
        _compressionTime = null;
        _statusMessage = null;
      });

      await _compressVideo();
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  Future<void> _compressVideo() async {
    if (_originalVideo == null) return;

    setState(() {
      _isCompressing = true;
      _statusMessage = 'Compressing video...';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final result = await MediaCompressor.compressVideo(
        VideoCompressionConfig(
          path: _originalVideo!.path,
          quality: _quality,
        ),
      );

      stopwatch.stop();

      if (result.isSuccess) {
        final compressedFile = File(result.path!);
        final compressedSize = await compressedFile.length();

        setState(() {
          _compressedVideo = compressedFile;
          _compressedSize = compressedSize;
          _compressionTime = stopwatch.elapsed.inSeconds;
          _statusMessage = 'Compression complete!';
          _isCompressing = false;
        });
      } else {
        setState(() {
          _statusMessage = 'Error: ${result.error!.message}';
          _isCompressing = false;
        });
      }
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _statusMessage = 'Error: $e';
        _isCompressing = false;
      });
    }
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedPercentage = _originalSize != null && _compressedSize != null
        ? ((1 - (_compressedSize! / _originalSize!)) * 100).toInt()
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pick Video Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed:
                      _isCompressing ? null : () => _pickVideo(ImageSource.camera),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Record'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed:
                      _isCompressing ? null : () => _pickVideo(ImageSource.gallery),
                  icon: const Icon(Icons.video_library),
                  label: const Text('Gallery'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Card
          if (_originalSize != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Original',
                          _formatBytes(_originalSize!),
                          Icons.video_file,
                          Colors.blue,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatItem(
                          'Compressed',
                          _compressedSize != null
                              ? _formatBytes(_compressedSize!)
                              : '-',
                          Icons.compress,
                          Colors.green,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatItem(
                          'Saved',
                          _compressedSize != null ? '$savedPercentage%' : '-',
                          Icons.trending_down,
                          Colors.orange,
                        ),
                      ],
                    ),
                    if (_compressionTime != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer,
                                size: 16, color: Colors.purple.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Completed in ${_compressionTime}s',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_compressedSize != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 1 - (_compressedSize! / _originalSize!),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            savedPercentage > 50 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Quality Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compression Quality',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<VideoQuality>(
                    segments: const [
                      ButtonSegment(
                        value: VideoQuality.low,
                        label: Text('Low'),
                        icon: Icon(Icons.battery_saver),
                      ),
                      ButtonSegment(
                        value: VideoQuality.medium,
                        label: Text('Medium'),
                        icon: Icon(Icons.balance),
                      ),
                      ButtonSegment(
                        value: VideoQuality.high,
                        label: Text('High'),
                        icon: Icon(Icons.high_quality),
                      ),
                    ],
                    selected: {_quality},
                    onSelectionChanged: _isCompressing
                        ? null
                        : (Set<VideoQuality> newSelection) {
                            setState(() => _quality = newSelection.first);
                            if (_originalVideo != null) _compressVideo();
                          },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getQualityIcon(_quality),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _quality.name.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getQualityDescription(_quality),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Status Card
          if (_isCompressing) ...[
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage ?? 'Processing...',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Video Info Card
          if (_originalVideo != null || _compressedVideo != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video Files',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_originalVideo != null) ...[
                      _buildVideoFileInfo(
                        'Original Video',
                        _originalVideo!,
                        _originalSize!,
                        Icons.video_file,
                        Colors.blue,
                      ),
                      if (_compressedVideo != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                      ],
                    ],
                    if (_compressedVideo != null) ...[
                      CupertinoButton(
                        onPressed: () {
                          Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NativeVideoPlayerScreen(
      videoPath: _compressedVideo?.path,
    ),
  ),
);

                        },
                        minSize: 0,
                        padding: EdgeInsets.zero,
                        child: _buildVideoFileInfo(
                          'Compressed Video',
                          _compressedVideo!,
                          _compressedSize!,
                          Icons.compress,
                          Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoFileInfo(
    String label,
    File file,
    int size,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatBytes(size),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  file.path.split('/').last,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getQualityIcon(VideoQuality quality) {
    switch (quality) {
      case VideoQuality.low:
        return Icons.battery_saver;
      case VideoQuality.medium:
        return Icons.balance;
      case VideoQuality.high:
        return Icons.high_quality;
    }
  }

  String _getQualityDescription(VideoQuality quality) {
    switch (quality) {
      case VideoQuality.low:
        return '480p resolution, ~800 Kbps bitrate, max compression';
      case VideoQuality.medium:
        return '720p resolution, ~2 Mbps bitrate, balanced';
      case VideoQuality.high:
        return '1080p resolution, ~4 Mbps bitrate, best quality';
    }
  }
}