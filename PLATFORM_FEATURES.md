# Platform-Specific Features

This document details the platform-specific implementations, features, and capabilities of the Media Compressor plugin.

## Overview

While the Media Compressor plugin provides a unified API across both platforms, each platform uses its own native libraries optimized for that ecosystem. This results in some differences in capabilities and behavior.

## Video Compression

### Android Implementation

**Technology:** AndroidX Media3 Transformer

The Android implementation uses the powerful Media3 Transformer library for precise video compression control.

#### Features

✅ **Precise Bitrate Control**
- Exact bitrate targeting for video encoding
- Custom encoder settings via `DefaultEncoderFactory`

✅ **Resolution Scaling**
- Automatic scaling to target resolutions
- Maintains aspect ratio during scaling

✅ **Progress Tracking**
- Real-time compression progress via EventChannel
- Progress updates during encoding process

✅ **Advanced Encoder Settings**
- Hardware-accelerated H.264 encoding
- Fallback to software encoding if needed
- Configurable video encoder settings

#### Quality Preset Details

| Quality | Resolution | Bitrate | Use Case |
|---------|-----------|---------|----------|
| `low` | 480p (640x480) | 500 kbps | Quick sharing, minimal file size |
| `medium` | 720p (1280x720) | 1.5 Mbps | Social media, general sharing |
| `high` | 1080p (1920x1080) | 3 Mbps | High-quality archival |

#### Technical Details

- **Video Codec**: H.264 (MPEG-4 AVC)
- **Container Format**: MP4
- **Audio Handling**: Preserved without re-encoding
- **Scaling Method**: `ScaleAndRotateTransformation` with bilinear filtering
- **Processing**: Asynchronous with coroutines

#### Code Example (Progress Tracking)

```dart
// Android supports progress tracking via EventChannel
final eventChannel = EventChannel('native_compressor/progress');

eventChannel.receiveBroadcastStream().listen((event) {
  final progress = event['progress'] as double;
  final percentage = event['percentage'] as int;
  print('Compression progress: $percentage%');
});

final result = await MediaCompressor.compressVideo(
  VideoCompressionConfig(
    path: videoPath,
    quality: VideoQuality.medium,
  ),
);
```

### iOS Implementation

**Technology:** AVAssetExportSession

The iOS implementation uses Apple's built-in AVAssetExportSession for optimized video compression.

#### Features

✅ **System Presets**
- Leverages Apple's quality presets
- Optimized for iOS ecosystem

✅ **Network Optimization**
- `shouldOptimizeForNetworkUse` enabled
- Videos optimized for streaming

✅ **Native Integration**
- Seamless integration with iOS media frameworks
- Leverages Apple's hardware acceleration

#### Quality Preset Details

| Quality | iOS Preset | Characteristics |
|---------|-----------|-----------------|
| `low` | `AVAssetExportPresetLowQuality` | Smallest file size, lower quality |
| `medium` | `AVAssetExportPresetMediumQuality` | Balanced quality and size |
| `high` | `AVAssetExportPresetHighestQuality` | Best quality, larger file size |

#### Technical Details

- **Export Session**: AVAssetExportSession
- **Container Format**: MP4
- **Network Optimization**: Enabled
- **Audio Handling**: Preserved during export
- **Processing**: Asynchronous with completion handlers

#### Code Example

```dart
// iOS compression (no progress tracking yet)
final result = await MediaCompressor.compressVideo(
  VideoCompressionConfig(
    path: videoPath,
    quality: VideoQuality.medium,
  ),
);
```

### Platform Comparison

| Feature | Android | iOS |
|---------|---------|-----|
| Precise Bitrate Control | ✅ Yes | ❌ No (uses presets) |
| Resolution Targeting | ✅ Yes (480p/720p/1080p) | ❌ No (preset-based) |
| Progress Tracking | ✅ Yes (EventChannel) | 🚧 Under Development |
| Network Optimization | 🚧 Under Development | ✅ Yes |
| Hardware Acceleration | ✅ Yes (with fallback) | ✅ Yes (automatic) |
| Custom Encoder Settings | ✅ Yes | ❌ No |

## Image Compression

### Android Implementation

**Technology:** Android Bitmap + ExifInterface

#### Features

✅ **EXIF Orientation Handling**
- Reads EXIF orientation data
- Automatically rotates/flips images

✅ **Memory Management**
- RGB_565 color format for reduced memory
- Bitmap recycling after compression

✅ **Quality Control**
- JPEG compression with quality 0-100
- Configurable resolution limits

#### Technical Details

- **Format**: JPEG output
- **Color Space**: RGB_565 (optimized)
- **Orientation**: Full EXIF support (8 orientations)
- **Scaling**: Bilinear interpolation

### iOS Implementation

**Technology:** UIKit + UIImage

#### Features

✅ **EXIF Orientation Handling**
- UIImage orientation detection
- CGContext-based rotation/flipping

✅ **High-Quality Rendering**
- UIGraphicsImageRenderer for modern rendering
- Maintains color accuracy

✅ **Quality Control**
- JPEG compression with quality 0-100
- Configurable resolution limits

#### Technical Details

- **Format**: JPEG output
- **Rendering**: UIGraphicsImageRenderer
- **Orientation**: Full UIImage orientation support
- **Scaling**: UIKit's high-quality scaling

### Platform Comparison (Images)

| Feature | Android | iOS |
|---------|---------|-----|
| EXIF Orientation | ✅ Yes (8 types) | ✅ Yes (8 types) |
| Quality Control | ✅ 0-100 | ✅ 0-100 |
| Resolution Limiting | ✅ Yes | ✅ Yes |
| Memory Optimization | ✅ RGB_565 | ✅ Automatic |
| Format Support | JPEG | JPEG |

## Error Codes

### Cross-Platform Error Codes

These error codes are used by both platforms:

- `INVALID_ARGUMENT` - Invalid arguments (quality out of range, invalid dimensions)
- `COMPRESSION_ERROR` - Native compression failed
- `FILE_NOT_FOUND` - Input file doesn't exist
- `NULL_RESULT` - Compression returned null/empty result
- `TIMEOUT` - Video compression exceeded timeout
- `UNKNOWN_ERROR` - Unexpected error occurred

### iOS-Specific Error Codes

Additional error codes only thrown on iOS:

- `LOAD_ERROR` - Failed to load image file (UIImage creation failed)
- `EXPORT_ERROR` - Failed to create AVAssetExportSession
- `EXPORT_FAILED` - AVAssetExportSession export failed
- `EXPORT_CANCELLED` - Video export was cancelled by system

## Future Roadmap

### Planned for iOS

🚧 **Progress Tracking**
- Event-based progress updates during video compression
- Similar to Android implementation

🚧 **Precise Bitrate Control**
- Custom bitrate settings beyond Apple's presets
- Resolution targeting similar to Android

### Planned for Android

🚧 **Network Optimization**
- Optimize MP4 file structure for streaming
- Similar to iOS `shouldOptimizeForNetworkUse`

### Planned for Both Platforms

🔮 **Batch Compression**
- Compress multiple files in one call
- Progress tracking per file

🔮 **Format Support**
- PNG output for images
- WebP support
- Additional video codecs (H.265/HEVC)

🔮 **Advanced Options**
- Frame rate control
- Audio bitrate settings
- Custom encoder profiles

## Performance Characteristics

### Android

**Image Compression:**
- Small images (<2MB): 50-200ms
- Large images (5-10MB): 200-500ms
- Very large images (>10MB): 500ms-2s

**Video Compression:**
- 30s video @ 720p medium: 10-30s
- 1min video @ 720p medium: 20-60s
- Highly dependent on device hardware

### iOS

**Image Compression:**
- Small images (<2MB): 50-150ms
- Large images (5-10MB): 150-400ms
- Very large images (>10MB): 400ms-1.5s

**Video Compression:**
- 30s video @ medium preset: 15-45s
- 1min video @ medium preset: 30-90s
- Generally faster than Android on newer devices

## Best Practices by Platform

### Android

1. **Use Progress Tracking**: Display progress for better UX
2. **Handle Timeouts**: Large videos may need extended timeouts
3. **Test Hardware**: Performance varies significantly by device
4. **Consider Quality**: `medium` preset (720p) is optimal for most cases

### iOS

1. **Network Optimization**: Already enabled, great for sharing
2. **System Presets**: Trust Apple's presets - they're well-optimized
3. **Handle All Export States**: Check for cancelled/failed states
4. **File Management**: Clean up temp files after upload/share

## Support and Issues

For platform-specific issues:

**Android Issues:**
- Media3 Transformer errors
- Bitrate/resolution problems
- Progress tracking issues

**iOS Issues:**
- AVAssetExportSession failures
- Preset-related questions
- Export state handling

Please report platform-specific issues on the [GitHub repository](https://github.com/yourusername/media_compressor/issues) with the platform label.

---

**Last Updated:** November 2025  
**Plugin Version:** 1.0.0