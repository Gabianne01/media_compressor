import 'dart:async';
import 'media_compressor_platform_interface.dart';
import 'src/video_quality.dart';
import 'src/image_quality.dart';

/// A class that provides media compression functionality
class MediaCompressor {
  /// Get the platform version
  Future<String?> getPlatformVersion() {
    return MediaCompressorPlatform.instance.getPlatformVersion();
  }

  /// Compress an image with basic quality setting
  /// 
  /// [path] The path to the source image file
  /// [quality] The compression quality (0-100)
  Future<String?> compressImage({
    required String path,
    required int quality,
  }) {
    if (quality < 0 || quality > 100) {
      throw ArgumentError('Quality must be between 0 and 100');
    }
    return MediaCompressorPlatform.instance.compressImage(path, quality);
  }

  /// Compress an image with advanced options
  /// 
  /// Returns a map containing compressed file details:
  /// - path: String - Path to compressed file
  /// - originalSize: int - Original file size in bytes
  /// - compressedSize: int - Compressed file size in bytes
  /// - compressionRatio: double - Compression ratio
  Future<Map<String, dynamic>?> compressImageWithOptions({
    required String path,
    required int quality,
    int? maxWidth,
    int? maxHeight,
    ImageFormat format = ImageFormat.jpeg,
    bool keepMetadata = false,
  }) {
    if (quality < 0 || quality > 100) {
      throw ArgumentError('Quality must be between 0 and 100');
    }

    final options = {
      'quality': quality,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'format': format.name,
      'keepMetadata': keepMetadata,
    };

    return MediaCompressorPlatform.instance.compressImageWithOptions(path, options);
  }

  /// Compress a video with quality preset
  /// 
  /// [path] The path to the source video file
  /// [quality] The compression quality preset
  Future<String?> compressVideo({
    required String path,
    required VideoQuality quality,
  }) {
    return MediaCompressorPlatform.instance.compressVideo(path, quality.name);
  }

  /// Compress a video with advanced options
  /// 
  /// Returns a map containing compressed file details:
  /// - path: String - Path to compressed file
  /// - originalSize: int - Original file size in bytes
  /// - compressedSize: int - Compressed file size in bytes
  /// - compressionRatio: double - Compression ratio
  /// - duration: int - Processing duration in milliseconds
  Future<Map<String, dynamic>?> compressVideoWithOptions({
    required String path,
    required VideoQuality quality,
    int? bitrate,
    int? maxWidth,
    int? maxHeight,
    int? frameRate,
    void Function(double)? onProgress,
  }) {
    if (onProgress != null) {
      compressionProgress.listen(onProgress);
    }

    final options = {
      'quality': quality.name,
      'bitrate': bitrate ?? quality.suggestedBitrate,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight ?? quality.suggestedHeight,
      'frameRate': frameRate ?? 30,
    };

    return MediaCompressorPlatform.instance.compressVideoWithOptions(path, options);
  }

  /// Compress multiple images in batch
  /// 
  /// [paths] List of image file paths
  /// [quality] Compression quality (0-100)
  Future<List<String?>> compressImageBatch({
    required List<String> paths,
    required int quality,
    void Function(int current, int total)? onProgress,
  }) async {
    if (quality < 0 || quality > 100) {
      throw ArgumentError('Quality must be between 0 and 100');
    }

    final results = <String?>[];
    for (var i = 0; i < paths.length; i++) {
      final result = await compressImage(
        path: paths[i],
        quality: quality,
      );
      results.add(result);
      onProgress?.call(i + 1, paths.length);
    }
    return results;
  }

  /// Cancel ongoing compression task
  Future<void> cancelCompression() {
    return MediaCompressorPlatform.instance.cancelCompression();
  }

  /// Get list of supported image formats
  Future<List<String>> getSupportedImageFormats() {
    return MediaCompressorPlatform.instance.getSupportedImageFormats();
  }

  /// Get list of supported video formats
  Future<List<String>> getSupportedVideoFormats() {
    return MediaCompressorPlatform.instance.getSupportedVideoFormats();
  }

  /// Stream of compression progress (0-100)
  Stream<double> get compressionProgress {
    return MediaCompressorPlatform.instance.compressionProgress;
  }
}

