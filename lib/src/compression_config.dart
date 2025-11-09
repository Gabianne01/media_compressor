/// Configuration for image compression operations.
///
/// This class encapsulates all parameters needed for image compression
/// and provides validation to ensure proper usage.
class ImageCompressionConfig {
  /// Path to the image file to compress
  final String path;

  /// Compression quality (0-100)
  /// - 0: Maximum compression, lowest quality
  /// - 100: Minimum compression, highest quality
  /// - Default: 80 (good balance)
  final int quality;

  /// Optional maximum width in pixels
  /// If specified, image will be scaled down if larger
  final int? maxWidth;

  /// Optional maximum height in pixels
  /// If specified, image will be scaled down if larger
  final int? maxHeight;

  const ImageCompressionConfig({
    required this.path,
    this.quality = 80,
    this.maxWidth,
    this.maxHeight,
  }) : assert(
         quality >= 0 && quality <= 100,
         'Quality must be between 0 and 100',
       );

  /// Convert configuration to a map for platform channel communication
  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'quality': quality,
      if (maxWidth != null) 'maxWidth': maxWidth,
      if (maxHeight != null) 'maxHeight': maxHeight,
    };
  }

  @override
  String toString() {
    return 'ImageCompressionConfig(path: $path, quality: $quality, '
        'maxWidth: $maxWidth, maxHeight: $maxHeight)';
  }
}

/// Configuration for video compression operations.
///
/// This class encapsulates all parameters needed for video compression.
class VideoCompressionConfig {
  /// Path to the video file to compress
  final String path;

  /// Quality preset for compression
  /// Default: [VideoQuality.medium]
  final VideoQuality quality;

  const VideoCompressionConfig({
    required this.path,
    this.quality = VideoQuality.medium,
  });

  /// Convert configuration to a map for platform channel communication
  Map<String, dynamic> toMap() {
    return {'path': path, 'quality': quality.value};
  }

  @override
  String toString() {
    return 'VideoCompressionConfig(path: $path, quality: ${quality.value})';
  }
}

/// Video quality presets for compression.
///
/// These presets balance file size and quality for common use cases.
enum VideoQuality {
  /// Low quality - smaller file size, lower visual quality
  /// Best for: Previews, thumbnails, or bandwidth-constrained scenarios
  low('low'),

  /// Medium quality - balanced file size and quality
  /// Best for: General sharing, social media, most use cases
  medium('medium'),

  /// High quality - larger file size, better visual quality
  /// Best for: Archival, professional use, high-quality playback
  high('high');

  /// String value for native platform communication
  final String value;

  const VideoQuality(this.value);
}


// /// Configuration for image compression
// class ImageCompressionConfig {
//   /// Path to the image file
//   final String path;

//   /// Quality of compression (0-100)
//   /// Higher value means better quality but larger file size
//   final int quality;

//   /// Maximum width of the output image
//   /// If null, original width is used
//   final int? maxWidth;

//   /// Maximum height of the output image
//   /// If null, original height is used
//   final int? maxHeight;

//   const ImageCompressionConfig({
//     required this.path,
//     this.quality = 80,
//     this.maxWidth,
//     this.maxHeight,
//   }) : assert(quality >= 0 && quality <= 100, 'Quality must be between 0 and 100');

//   Map<String, dynamic> toMap() {
//     return {
//       'path': path,
//       'quality': quality,
//       if (maxWidth != null) 'maxWidth': maxWidth,
//       if (maxHeight != null) 'maxHeight': maxHeight,
//     };
//   }
// }

// /// Configuration for video compression
// class VideoCompressionConfig {
//   /// Path to the video file
//   final String path;

//   /// Quality preset for compression
//   final VideoQuality quality;

//   const VideoCompressionConfig({
//     required this.path,
//     this.quality = VideoQuality.medium,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'path': path,
//       'quality': quality.value,
//     };
//   }
// }

// /// Video quality presets
// enum VideoQuality {
//   low('low'),
//   medium('medium'),
//   high('high');

//   final String value;
//   const VideoQuality(this.value);
// }