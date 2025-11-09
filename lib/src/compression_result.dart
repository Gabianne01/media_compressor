/// Result of a compression operation.
///
/// This class represents the outcome of an image or video compression operation.
/// It contains either a successful path to the compressed file or error information
/// if the compression failed.
///
/// Example:
/// ```dart
/// final result = await MediaCompressor.compressImage(config);
/// 
/// if (result.isSuccess) {
///   print('Success: ${result.path}');
/// } else {
///   print('Failed: ${result.error?.message}');
/// }
/// ```
class CompressionResult {
  /// Path to the compressed file (null if compression failed)
  final String? path;

  /// Error information if compression failed (null if successful)
  final CompressionError? error;

  /// Whether the compression was successful
  bool get isSuccess => path != null && error == null;

  /// Whether the compression failed
  bool get isFailure => !isSuccess;

  const CompressionResult({
    this.path,
    this.error,
  });

  /// Create a successful compression result
  ///
  /// Parameters:
  /// - [path]: Path to the successfully compressed file
  factory CompressionResult.success(String path) {
    return CompressionResult(path: path);
  }

  /// Create a failed compression result
  ///
  /// Parameters:
  /// - [error]: Error information describing what went wrong
  factory CompressionResult.failure(CompressionError error) {
    return CompressionResult(error: error);
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'CompressionResult.success(path: $path)';
    } else {
      return 'CompressionResult.failure(error: $error)';
    }
  }
}

/// Error information for failed compression operations.
///
/// This class encapsulates all error details including a code for programmatic
/// handling and a human-readable message.
///
/// Common error codes:
/// - `FILE_NOT_FOUND`: Input file doesn't exist
/// - `INVALID_PATH`: Invalid file path provided
/// - `COMPRESSION_FAILED`: Native compression operation failed
/// - `NULL_RESULT`: Unexpected null result from native code
/// - `TIMEOUT`: Operation exceeded timeout duration
/// - `UNKNOWN_ERROR`: Unexpected error occurred
class CompressionError {
  /// Error code for programmatic error handling
  final String code;

  /// Human-readable error message
  final String message;

  /// Additional error details (optional)
  /// May contain platform-specific error information
  final dynamic details;

  const CompressionError({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() {
    if (details != null) {
      return 'CompressionError(code: $code, message: $message, details: $details)';
    }
    return 'CompressionError(code: $code, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CompressionError &&
        other.code == code &&
        other.message == message &&
        other.details == details;
  }

  @override
  int get hashCode => code.hashCode ^ message.hashCode ^ details.hashCode;
}

// /// Result of a compression operation
// class CompressionResult {
//   /// Path to the compressed file
//   final String? path;

//   /// Error information if compression failed
//   final CompressionError? error;

//   /// Whether the compression was successful
//   bool get isSuccess => path != null && error == null;

//   const CompressionResult({
//     this.path,
//     this.error,
//   });

//   factory CompressionResult.success(String path) {
//     return CompressionResult(path: path);
//   }

//   factory CompressionResult.failure(CompressionError error) {
//     return CompressionResult(error: error);
//   }
// }

// /// Error information for failed compression
// class CompressionError {
//   /// Error code
//   final String code;

//   /// Error message
//   final String message;

//   /// Additional error details
//   final dynamic details;

//   const CompressionError({
//     required this.code,
//     required this.message,
//     this.details,
//   });

//   @override
//   String toString() {
//     return 'CompressionError(code: $code, message: $message, details: $details)';
//   }
// }