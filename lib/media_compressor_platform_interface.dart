import 'package:media_compressor/media_compressor_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:async';

abstract class MediaCompressorPlatform extends PlatformInterface {
  /// Constructs a MediaCompressorPlatform.
  MediaCompressorPlatform() : super(token: _token);

  static final Object _token = Object();

  static MediaCompressorPlatform _instance = MethodChannelMediaCompressor();

  /// The default instance of [MediaCompressorPlatform] to use.
  static MediaCompressorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MediaCompressorPlatform] when
  /// they register themselves.
  static set instance(MediaCompressorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Stream controller for compression progress
  final _progressController = StreamController<double>.broadcast();

  /// Get platform version
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Compress image with basic quality setting
  Future<String?> compressImage(String path, int quality) {
    throw UnimplementedError('compressImage() has not been implemented.');
  }

  /// Compress image with advanced options
  Future<Map<String, dynamic>?> compressImageWithOptions(
    String path,
    Map<String, dynamic> options,
  ) {
    throw UnimplementedError('compressImageWithOptions() has not been implemented.');
  }

  /// Compress video with quality preset
  Future<String?> compressVideo(String path, String quality) {
    throw UnimplementedError('compressVideo() has not been implemented.');
  }

  /// Compress video with advanced options
  Future<Map<String, dynamic>?> compressVideoWithOptions(
    String path,
    Map<String, dynamic> options,
  ) {
    throw UnimplementedError('compressVideoWithOptions() has not been implemented.');
  }

  /// Cancel ongoing compression task
  Future<void> cancelCompression() {
    throw UnimplementedError('cancelCompression() has not been implemented.');
  }

  /// Get supported image formats
  Future<List<String>> getSupportedImageFormats() {
    throw UnimplementedError('getSupportedImageFormats() has not been implemented.');
  }

  /// Get supported video formats
  Future<List<String>> getSupportedVideoFormats() {
    throw UnimplementedError('getSupportedVideoFormats() has not been implemented.');
  }

  /// Stream of compression progress (0-100)
  Stream<double> get compressionProgress => _progressController.stream;

  /// Update compression progress
  void updateProgress(double progress) {
    _progressController.add(progress);
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}
