
/// Video compression quality presets
enum VideoQuality {
  /// Very low quality, smallest file size
  veryLow,
  
  /// Low quality, small file size
  low,
  
  /// Medium quality, balanced file size
  medium,
  
  /// High quality, larger file size
  high,
  
  /// Very high quality, largest file size
  veryHigh,
}

extension VideoQualityExtension on VideoQuality {
  /// Get suggested bitrate for this quality level (in bits per second)
  int get suggestedBitrate {
    switch (this) {
      case VideoQuality.veryLow:
        return 500000; // 500 kbps
      case VideoQuality.low:
        return 1000000; // 1 Mbps
      case VideoQuality.medium:
        return 2000000; // 2 Mbps
      case VideoQuality.high:
        return 4000000; // 4 Mbps
      case VideoQuality.veryHigh:
        return 8000000; // 8 Mbps
    }
  }
  
  /// Get suggested resolution height for this quality level
  int get suggestedHeight {
    switch (this) {
      case VideoQuality.veryLow:
        return 360;
      case VideoQuality.low:
        return 480;
      case VideoQuality.medium:
        return 720;
      case VideoQuality.high:
        return 1080;
      case VideoQuality.veryHigh:
        return 2160; // 4K
    }
  }
}