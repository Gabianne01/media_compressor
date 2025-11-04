/// Supported image formats for compression
enum ImageFormat {
  /// JPEG format - best for photos
  jpeg,
  
  /// PNG format - best for images with transparency
  png,
  
  /// WebP format - modern format with good compression
  webp,
  
  /// HEIC format - Apple's efficient format (iOS only)
  heic,
}

extension ImageFormatExtension on ImageFormat {
  /// Get file extension for this format
  String get extension {
    switch (this) {
      case ImageFormat.jpeg:
        return 'jpg';
      case ImageFormat.png:
        return 'png';
      case ImageFormat.webp:
        return 'webp';
      case ImageFormat.heic:
        return 'heic';
    }
  }
  
  /// Get MIME type for this format
  String get mimeType {
    switch (this) {
      case ImageFormat.jpeg:
        return 'image/jpeg';
      case ImageFormat.png:
        return 'image/png';
      case ImageFormat.webp:
        return 'image/webp';
      case ImageFormat.heic:
        return 'image/heic';
    }
  }
  
  /// Check if format supports transparency
  bool get supportsTransparency {
    switch (this) {
      case ImageFormat.jpeg:
      case ImageFormat.heic:
        return false;
      case ImageFormat.png:
      case ImageFormat.webp:
        return true;
    }
  }
}