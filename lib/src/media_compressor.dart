import 'dart:async';
import 'package:flutter/services.dart';
import 'package:media_compressor/media_compressor.dart';

/// A singleton class for compressing images and videos using native platform implementations.
///
/// This class provides static methods for compressing media files with proper error handling
/// and type safety. All compression operations are performed on the native platform side
/// for optimal performance.
///
/// Example usage:
/// ```dart
/// final result = await MediaCompressor.compressImage(
///   ImageCompressionConfig(
///     path: '/path/to/image.jpg',
///     quality: 80,
///   ),
/// );
/// ```
class MediaCompressor {
  /// Private constructor to prevent instantiation
  MediaCompressor._();

  /// Singleton instance
  static final MediaCompressor _instance = MediaCompressor._();

  /// Get the singleton instance
  static MediaCompressor get instance => _instance;

  /// Method channel for communication with native code
  static const MethodChannel _channel = MethodChannel('native_compressor');

  /// Compress an image file with the specified configuration.
  ///
  /// This method compresses an image file using native platform implementations
  /// for optimal performance and quality.
  ///
  /// Parameters:
  /// - [config]: Configuration object containing compression parameters
  ///
  /// Returns a [CompressionResult] containing either:
  /// - Success: The path to the compressed image file
  /// - Failure: A [CompressionError] with details about what went wrong
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
  ///   print('Error: ${result.error?.message}');
  /// }
  /// ```
  static Future<CompressionResult> compressImage(
    ImageCompressionConfig config,
  ) async {
    try {
      // Call native method
      final String? result = await _channel.invokeMethod(
        'compressImage',
        config.toMap(),
      );

      // Handle result
      if (result != null && result.isNotEmpty) {
        return CompressionResult.success(result);
      } else {
        return CompressionResult.failure(
          const CompressionError(
            code: 'NULL_RESULT',
            message: 'Compression returned null or empty result',
          ),
        );
      }
    } on PlatformException catch (e) {
      return CompressionResult.failure(
        CompressionError(
          code: e.code,
          message: e.message ?? 'Platform error occurred during compression',
          details: e.details,
        ),
      );
    } on TimeoutException catch (e) {
      return CompressionResult.failure(
        CompressionError(
          code: 'TIMEOUT',
          message: e.message ?? 'Image compression timed out',
        ),
      );
    } catch (e) {
      return CompressionResult.failure(
        CompressionError(
          code: 'UNKNOWN_ERROR',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Compress a video file with the specified configuration.
  ///
  /// This method compresses a video file using native platform implementations.
  /// Video compression can take significant time depending on file size and quality settings.
  ///
  /// Parameters:
  /// - [config]: Configuration object containing compression parameters
  /// - [timeout]: Optional timeout duration (default: 5 minutes)
  ///
  /// Returns a [CompressionResult] containing either:
  /// - Success: The path to the compressed video file
  /// - Failure: A [CompressionError] with details about what went wrong
  ///
  /// Example:
  /// ```dart
  /// final result = await MediaCompressor.compressVideo(
  ///   VideoCompressionConfig(
  ///     path: '/path/to/video.mp4',
  ///     quality: VideoQuality.medium,
  ///   ),
  ///   timeout: Duration(minutes: 10), // Optional custom timeout
  /// );
  ///
  /// if (result.isSuccess) {
  ///   print('Compressed video: ${result.path}');
  /// } else {
  ///   print('Error: ${result.error?.message}');
  /// }
  /// ```
  static Future<CompressionResult> compressVideo(
    VideoCompressionConfig config, {
    Duration? timeout,
  }) async {
    try {
      // Video compression can take longer, so we use a longer default timeout
      final effectiveTimeout = timeout ?? const Duration(minutes: 5);

      // Call native method with timeout
      final result = await _channel
          .invokeMethod(
            'compressVideo',
            config.toMap(),
          )
          .timeout(
            effectiveTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Video compression timed out after ${effectiveTimeout.inMinutes} minutes. '
                'Try with a smaller video, lower quality, or increase the timeout.',
              );
            },
          );

      // Handle result
      if (result != null && result is String && result.isNotEmpty) {
        return CompressionResult.success(result);
      } else {
        return CompressionResult.failure(
          const CompressionError(
            code: 'NULL_RESULT',
            message: 'Compression returned null or invalid result',
          ),
        );
      }
    } on PlatformException catch (e) {
      return CompressionResult.failure(
        CompressionError(
          code: e.code,
          message: e.message ?? 'Platform error occurred during compression',
          details: e.details,
        ),
      );
    } on TimeoutException catch (e) {
      return CompressionResult.failure(
        CompressionError(
          code: 'TIMEOUT',
          message: e.message ?? 'Video compression timed out',
        ),
      );
    } catch (e) {
      return CompressionResult.failure(
        CompressionError(
          code: 'UNKNOWN_ERROR',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }
}




/// Exception thrown when an operation times out
class TimeoutException implements Exception {
  /// Error message describing the timeout
  final String? message;

  const TimeoutException([this.message]);

  @override
  String toString() => message ?? 'Operation timed out';
}





// import 'dart:async';
// import 'package:flutter/services.dart';
// import 'compression_config.dart';
// import 'compression_result.dart';


// class MediaCompressor {
//   static const MethodChannel _channel = MethodChannel('native_compressor');
 


//   /// Compress an image file
//   ///
//   /// Returns a [CompressionResult] containing the path to the compressed image
//   /// or an error if compression failed.
//   ///
//   /// Example:
//   /// ```dart
//   /// final result = await MediaCompressor.compressImage(
//   ///   ImageCompressionConfig(
//   ///     path: '/path/to/image.jpg',
//   ///     quality: 80,
//   ///     maxWidth: 1920,
//   ///     maxHeight: 1080,
//   ///   ),
//   /// );
//   ///
//   /// if (result.isSuccess) {
//   ///   print('Compressed image: ${result.path}');
//   /// } else {
//   ///   print('Error: ${result.error}');
//   /// }
//   /// ```
//   static Future<CompressionResult> compressImage(
//     ImageCompressionConfig config,
//   ) async {
//     try {
//       final String? result = await _channel.invokeMethod(
//         'compressImage',
//         config.toMap(),
//       );

//       if (result != null) {
//         return CompressionResult.success(result);
//       } else {
//         return CompressionResult.failure(
//           const CompressionError(
//             code: 'NULL_RESULT',
//             message: 'Compression returned null result',
//           ),
//         );
//       }
//     } on PlatformException catch (e) {
//       return CompressionResult.failure(
//         CompressionError(
//           code: e.code,
//           message: e.message ?? 'Unknown error',
//           details: e.details,
//         ),
//       );
//     } catch (e) {
//       return CompressionResult.failure(
//         CompressionError(
//           code: 'UNKNOWN_ERROR',
//           message: e.toString(),
//         ),
//       );
//     }
//   }

//   /// Compress a video file
//   ///
//   /// Returns a [CompressionResult] containing the path to the compressed video
//   /// or an error if compression failed.
//   ///
//   /// Subscribe to [progressStream] before calling this method to receive progress updates.
//   ///
//   /// Video compression can take a while depending on the file size and quality settings.
//   /// The method will wait for the compression to complete.
//   ///
//   /// Example:
//   /// ```dart
//   /// // Optional: Listen to progress
//   /// final progressSubscription = MediaCompressor.progressStream.listen((progress) {
//   ///   print('Progress: ${progress.percentage}%');
//   /// });
//   /// 
//   /// final result = await MediaCompressor.compressVideo(
//   ///   VideoCompressionConfig(
//   ///     path: '/path/to/video.mp4',
//   ///     quality: VideoQuality.medium,
//   ///   ),
//   /// );
//   ///
//   /// await progressSubscription.cancel();
//   /// 
//   /// if (result.isSuccess) {
//   ///   print('Compressed video: ${result.path}');
//   /// } else {
//   ///   print('Error: ${result.error}');
//   /// }
//   /// ```
//   static Future<CompressionResult> compressVideo(
//     VideoCompressionConfig config, {
//     Duration? timeout,
//   }) async {
//     try {
//       // Video compression can take longer, so we use a longer timeout
//       // Default is 5 minutes, but can be overridden
//       final result = await _channel
//           .invokeMethod(
//             'compressVideo',
//             config.toMap(),
//           )
//           .timeout(
//             timeout ?? const Duration(minutes: 5),
//             onTimeout: () {
//               throw TimeoutException(
//                 'Video compression timed out. Try with a smaller video or lower quality.',
//               );
//             },
//           );

//       if (result != null && result is String) {
//         return CompressionResult.success(result);
//       } else {
//         return CompressionResult.failure(
//           const CompressionError(
//             code: 'NULL_RESULT',
//             message: 'Compression returned null result',
//           ),
//         );
//       }
//     } on TimeoutException catch (e) {
//       return CompressionResult.failure(
//         CompressionError(
//           code: 'TIMEOUT',
//           message: e.message ?? 'Video compression timed out',
//         ),
//       );
//     } on PlatformException catch (e) {
//       return CompressionResult.failure(
//         CompressionError(
//           code: e.code,
//           message: e.message ?? 'Unknown error',
//           details: e.details,
//         ),
//       );
//     } catch (e) {
//       return CompressionResult.failure(
//         CompressionError(
//           code: 'UNKNOWN_ERROR',
//           message: e.toString(),
//         ),
//       );
//     }
//   }
// }

// /// Exception thrown when an operation times out
// class TimeoutException implements Exception {
//   final String? message;

//   TimeoutException([this.message]);

//   @override
//   String toString() => message ?? 'Operation timed out';
// }