import 'dart:async';
import 'package:flutter/services.dart';
import 'compression_config.dart';
import 'compression_result.dart';

/// Progress information for video compression
class CompressionProgress {
  /// Progress value from 0.0 to 1.0
  final double progress;
  
  /// Percentage from 0 to 100
  final int percentage;

  CompressionProgress({
    required this.progress,
    required this.percentage,
  });

  factory CompressionProgress.fromMap(Map<dynamic, dynamic> map) {
    return CompressionProgress(
      progress: (map['progress'] as num).toDouble(),
      percentage: map['percentage'] as int,
    );
  }
}

/// Main class for media compression operations
class MediaCompressor {
  static const MethodChannel _channel = MethodChannel('native_compressor');
  static const EventChannel _progressChannel = EventChannel('native_compressor/progress');
  
  static Stream<CompressionProgress>? _progressStream;

  /// Get a stream of compression progress updates
  /// 
  /// Subscribe to this before calling [compressVideo] to receive progress updates
  /// 
  /// Example:
  /// ```dart
  /// MediaCompressor.progressStream.listen((progress) {
  ///   print('Compression progress: ${progress.percentage}%');
  /// });
  /// 
  /// final result = await MediaCompressor.compressVideo(config);
  /// ```
  static Stream<CompressionProgress> get progressStream {
    _progressStream ??= _progressChannel
        .receiveBroadcastStream()
        .map((event) => CompressionProgress.fromMap(event as Map));
    return _progressStream!;
  }

  /// Compress an image file
  ///
  /// Returns a [CompressionResult] containing the path to the compressed image
  /// or an error if compression failed.
  ///
  /// Example:
  /// ```dart
  /// final result = await MediaCompressor.compressImage(
  ///   ImageCompressionConfig(
  ///     path: '/path/to/image.jpg',
  ///     quality: 80,
  ///     maxWidth: 1920,
  ///     maxHeight: 1080,
  ///   ),
  /// );
  ///
  /// if (result.isSuccess) {
  ///   print('Compressed image: ${result.path}');
  /// } else {
  ///   print('Error: ${result.error}');
  /// }
  /// ```
  static Future<CompressionResult> compressImage(
    ImageCompressionConfig config,
  ) async {
    try {
      final String? result = await _channel.invokeMethod(
        'compressImage',
        config.toMap(),
      );

      if (result != null) {
        return CompressionResult.success(result);
      } else {
        return CompressionResult.failure(
          const CompressionError(
            code: 'NULL_RESULT',
            message: 'Compression returned null result',
          ),
        );
      }
    } on PlatformException catch (e) {
      return CompressionResult.failure(
        CompressionError(
          code: e.code,
          message: e.message ?? 'Unknown error',
          details: e.details,
        ),
      );
    } catch (e) {
      return CompressionResult.failure(
        CompressionError(
          code: 'UNKNOWN_ERROR',
          message: e.toString(),
        ),
      );
    }
  }

  /// Compress a video file
  ///
  /// Returns a [CompressionResult] containing the path to the compressed video
  /// or an error if compression failed.
  ///
  /// Subscribe to [progressStream] before calling this method to receive progress updates.
  ///
  /// Video compression can take a while depending on the file size and quality settings.
  /// The method will wait for the compression to complete.
  ///
  /// Example:
  /// ```dart
  /// // Optional: Listen to progress
  /// final progressSubscription = MediaCompressor.progressStream.listen((progress) {
  ///   print('Progress: ${progress.percentage}%');
  /// });
  /// 
  /// final result = await MediaCompressor.compressVideo(
  ///   VideoCompressionConfig(
  ///     path: '/path/to/video.mp4',
  ///     quality: VideoQuality.medium,
  ///   ),
  /// );
  ///
  /// await progressSubscription.cancel();
  /// 
  /// if (result.isSuccess) {
  ///   print('Compressed video: ${result.path}');
  /// } else {
  ///   print('Error: ${result.error}');
  /// }
  /// ```
  static Future<CompressionResult> compressVideo(
    VideoCompressionConfig config, {
    Duration? timeout,
  }) async {
    try {
      // Video compression can take longer, so we use a longer timeout
      // Default is 5 minutes, but can be overridden
      final result = await _channel
          .invokeMethod(
            'compressVideo',
            config.toMap(),
          )
          .timeout(
            timeout ?? const Duration(minutes: 5),
            onTimeout: () {
              throw TimeoutException(
                'Video compression timed out. Try with a smaller video or lower quality.',
              );
            },
          );

      if (result != null && result is String) {
        return CompressionResult.success(result);
      } else {
        return CompressionResult.failure(
          const CompressionError(
            code: 'NULL_RESULT',
            message: 'Compression returned null result',
          ),
        );
      }
    } on TimeoutException catch (e) {
      return CompressionResult.failure(
        CompressionError(
          code: 'TIMEOUT',
          message: e.message ?? 'Video compression timed out',
        ),
      );
    } on PlatformException catch (e) {
      return CompressionResult.failure(
        CompressionError(
          code: e.code,
          message: e.message ?? 'Unknown error',
          details: e.details,
        ),
      );
    } catch (e) {
      return CompressionResult.failure(
        CompressionError(
          code: 'UNKNOWN_ERROR',
          message: e.toString(),
        ),
      );
    }
  }
}

/// Exception thrown when an operation times out
class TimeoutException implements Exception {
  final String? message;

  TimeoutException([this.message]);

  @override
  String toString() => message ?? 'Operation timed out';
}