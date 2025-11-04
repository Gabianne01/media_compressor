# Media Compressor

A Flutter plugin for compressing images and videos efficiently using native platform implementations.

## Features

- ✅ Image compression with quality control
- ✅ Video compression with bitrate and resolution options
- ✅ Batch compression support
- ✅ Progress callbacks
- ✅ Cross-platform support (Android & iOS)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  media_compressor: ^1.0.0
```

## Usage

### Import the package

```dart
import 'package:media_compressor/media_compressor.dart';
```

### Compress an image

```dart
final compressor = MediaCompressor();

// Simple compression
final compressedPath = await compressor.compressImage(
  path: '/path/to/image.jpg',
  quality: 80, // 0-100
);

// Advanced compression with options
final result = await compressor.compressImageWithOptions(
  path: '/path/to/image.jpg',
  options: ImageCompressionOptions(
    quality: 80,
    maxWidth: 1920,
    maxHeight: 1080,
    format: ImageFormat.jpeg,
  ),
);
```

### Compress a video

```dart
final compressor = MediaCompressor();

// Simple compression
final compressedPath = await compressor.compressVideo(
  path: '/path/to/video.mp4',
  quality: VideoQuality.medium,
);

// Advanced compression with options
final result = await compressor.compressVideoWithOptions(
  path: '/path/to/video.mp4',
  options: VideoCompressionOptions(
    quality: VideoQuality.high,
    bitrate: 2000000, // 2 Mbps
    maxWidth: 1280,
    maxHeight: 720,
    frameRate: 30,
  ),
  onProgress: (progress) {
    print('Compression progress: ${progress}%');
  },
);
```

### Batch compression

```dart
final paths = [
  '/path/to/image1.jpg',
  '/path/to/image2.png',
  '/path/to/image3.jpg',
];

final results = await compressor.compressImageBatch(
  paths: paths,
  quality: 70,
  onProgress: (currentIndex, total) {
    print('Processing $currentIndex of $total');
  },
);
```

## Platform-specific Setup

### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

For Android 10 and above, add:

```xml
android:requestLegacyExternalStorage="true"
```

### iOS

Add the following to your `Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to compress media files.</string>
```

## API Reference

### MediaCompressor

The main class for media compression operations.

#### Methods

- `compressImage(String path, int quality)` - Compress an image with specified quality
- `compressImageWithOptions(String path, ImageCompressionOptions options)` - Compress with advanced options
- `compressVideo(String path, VideoQuality quality)` - Compress a video with preset quality
- `compressVideoWithOptions(String path, VideoCompressionOptions options)` - Compress with advanced options
- `compressImageBatch(List<String> paths, int quality)` - Batch compress images
- `cancelCompression()` - Cancel ongoing compression

### ImageCompressionOptions

- `quality` (int): Compression quality (0-100)
- `maxWidth` (int?): Maximum width in pixels
- `maxHeight` (int?): Maximum height in pixels
- `format` (ImageFormat): Output format (jpeg, png, webp)
- `keepMetadata` (bool): Whether to preserve EXIF data

### VideoCompressionOptions

- `quality` (VideoQuality): Preset quality level
- `bitrate` (int?): Target bitrate in bits per second
- `maxWidth` (int?): Maximum width in pixels
- `maxHeight` (int?): Maximum height in pixels
- `frameRate` (int?): Target frame rate
- `audioBitrate` (int?): Audio bitrate

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

MIT License - see the [LICENSE](LICENSE) file for details.

