import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'media_compressor_platform_interface.dart';

/// An implementation of [MediaCompressorPlatform] that uses method channels.
class MethodChannelMediaCompressor extends MediaCompressorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('media_compressor');
  final eventChannel = const EventChannel('media_compressor/progress');

  MethodChannelMediaCompressor() {
    eventChannel.receiveBroadcastStream().listen((progress) {
      if (progress is double) {
        updateProgress(progress);
      }
    });
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> compressImage(String path, int quality) async {
    final result = await methodChannel.invokeMethod<String>(
      'compressImage',
      {'path': path, 'quality': quality},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> compressImageWithOptions(
    String path,
    Map<String, dynamic> options,
  ) async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'compressImageWithOptions',
      {'path': path, 'options': options},
    );

    // Ensure proper casting to Map<String, dynamic>
    return result?.map((key, value) => MapEntry(key as String, value));
  }

  @override
  Future<String?> compressVideo(String path, String quality) async {
    final result = await methodChannel.invokeMethod<String>(
      'compressVideo',
      {'path': path, 'quality': quality},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> compressVideoWithOptions(
    String path,
    Map<String, dynamic> options,
  ) async {
    final result = await methodChannel.invokeMethod<Map<String, dynamic>>(
      'compressVideoWithOptions',
      {'path': path, 'options': options},
    );
    return result;
  }

  @override
  Future<void> cancelCompression() async {
    await methodChannel.invokeMethod<void>('cancelCompression');
  }

  @override
  Future<List<String>> getSupportedImageFormats() async {
    final formats = await methodChannel.invokeListMethod<String>('getSupportedImageFormats');
    return formats ?? [];
  }

  @override
  Future<List<String>> getSupportedVideoFormats() async {
    final formats = await methodChannel.invokeListMethod<String>('getSupportedVideoFormats');
    return formats ?? [];
  }
}
