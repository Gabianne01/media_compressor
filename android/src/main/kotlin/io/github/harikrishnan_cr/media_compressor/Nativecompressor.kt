package io.github.harikrishnan_cr.media_compressor

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.MediaMetadataRetriever
import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.ScaleAndRotateTransformation
import androidx.media3.effect.Presentation
import androidx.media3.transformer.Composition
import androidx.media3.transformer.DefaultEncoderFactory
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.UUID
import android.util.Log
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import androidx.media3.transformer.VideoEncoderSettings

data class CompressionError(
    val code: String,
    val message: String,
    val details: Any? = null
)

class NativeCompressor(private val context: Context) {

    companion object {
        private const val TAG = "NativeCompressor"
    }

    // ============================================================================
    // IMAGE COMPRESSION CODE
    // ============================================================================

    fun compressImage(
        imagePath: String,
        quality: Int,
        maxWidth: Int?,
        maxHeight: Int?,
        callback: (String?, CompressionError?) -> Unit
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val result = compressImageInternal(imagePath, quality, maxWidth, maxHeight)
                withContext(Dispatchers.Main) {
                    callback(result, null)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(null, CompressionError(
                        code = "COMPRESSION_ERROR",
                        message = e.message ?: "Unknown error occurred",
                        details = e.stackTraceToString()
                    ))
                }
            }
        }
    }

    private suspend fun compressImageInternal(
        imagePath: String,
        quality: Int,
        maxWidth: Int?,
        maxHeight: Int?
    ): String = withContext(Dispatchers.IO) {
        val inputFile = File(imagePath)
        if (!inputFile.exists()) {
            throw IOException("Image file not found at path: $imagePath")
        }

        val bitmap = decodeBitmapWithOrientation(imagePath)
            ?: throw IOException("Failed to decode image from path: $imagePath")

        try {
            val resizedBitmap = if (maxWidth != null && maxHeight != null) {
                resizeBitmap(bitmap, maxWidth, maxHeight)
            } else {
                bitmap
            }

            val outputFile = createOutputFile("jpg")
            FileOutputStream(outputFile).use { outputStream ->
                val compressed = resizedBitmap.compress(
                    Bitmap.CompressFormat.JPEG,
                    quality,
                    outputStream
                )
                
                if (!compressed) {
                    throw IOException("Failed to compress image")
                }
            }

            if (resizedBitmap != bitmap) {
                resizedBitmap.recycle()
            }
            bitmap.recycle()

            outputFile.absolutePath
        } catch (e: Exception) {
            bitmap.recycle()
            throw e
        }
    }

    private fun decodeBitmapWithOrientation(imagePath: String): Bitmap? {
        val options = BitmapFactory.Options().apply {
            inJustDecodeBounds = false
            inPreferredConfig = Bitmap.Config.RGB_565
        }
        
        val bitmap = BitmapFactory.decodeFile(imagePath, options) ?: return null

        val exif = try {
            ExifInterface(imagePath)
        } catch (e: IOException) {
            return bitmap
        }

        val orientation = exif.getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL
        )

        return rotateBitmap(bitmap, orientation)
    }

    private fun rotateBitmap(bitmap: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()

        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.postRotate(90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.postRotate(270f)
                matrix.postScale(-1f, 1f)
            }
            else -> return bitmap
        }

        return try {
            val rotatedBitmap = Bitmap.createBitmap(
                bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
            )
            if (rotatedBitmap != bitmap) {
                bitmap.recycle()
            }
            rotatedBitmap
        } catch (e: OutOfMemoryError) {
            e.printStackTrace()
            bitmap
        }
    }

    private fun resizeBitmap(bitmap: Bitmap, maxWidth: Int, maxHeight: Int): Bitmap {
        val width = bitmap.width
        val height = bitmap.height

        val widthRatio = maxWidth.toFloat() / width
        val heightRatio = maxHeight.toFloat() / height
        val ratio = minOf(widthRatio, heightRatio, 1f)

        if (ratio >= 1f) {
            return bitmap
        }

        val newWidth = (width * ratio).toInt()
        val newHeight = (height * ratio).toInt()

        return try {
            Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
        } catch (e: OutOfMemoryError) {
            e.printStackTrace()
            bitmap
        }
    }

    // ============================================================================
    // REAL VIDEO COMPRESSION using AndroidX Media3 Transformer
    // ============================================================================

    fun compressVideo(
        videoPath: String,
        quality: String,
        callback: (String?, CompressionError?) -> Unit,
        progressCallback: ((Float) -> Unit)? = null
    ) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                Log.d(TAG, "Starting EXTREME video compression with Media3 Transformer")
                val result = compressVideoInternal(videoPath, quality, progressCallback)
                withContext(Dispatchers.Main) {
                    callback(result, null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Video compression error", e)
                withContext(Dispatchers.Main) {
                    callback(null, CompressionError(
                        code = "COMPRESSION_ERROR",
                        message = e.message ?: "Unknown error occurred",
                        details = e.stackTraceToString()
                    ))
                }
            }
        }
    }

    private suspend fun compressVideoInternal(
        videoPath: String,
        quality: String,
        progressCallback: ((Float) -> Unit)? = null
    ): String = withContext(Dispatchers.IO) {
        val inputFile = File(videoPath)
        if (!inputFile.exists()) {
            throw IOException("Video file not found at path: $videoPath")
        }

        val outputFile = createOutputFile("mp4")
        
        Log.d(TAG, "Input: $videoPath")
        Log.d(TAG, "Output: ${outputFile.absolutePath}")
        Log.d(TAG, "Quality: $quality")

        try {
            // Determine compression settings based on quality
            val (targetHeight, videoBitrate) = when (quality.lowercase()) {
                "low" -> Pair(480, 500_000)      // 480p @ 500 Kbps - EXTREME compression
                "medium" -> Pair(720, 1_500_000)  // 720p @ 1.5 Mbps - High compression
                "high" -> Pair(1080, 3_000_000)  // 1080p @ 3 Mbps - Moderate compression
                else -> Pair(720, 1_500_000)
            }

            Log.d(TAG, "Target: ${targetHeight}p @ ${videoBitrate / 1000} Kbps")

            // Use Media3 Transformer for actual compression
            compressWithTransformer(
                inputPath = videoPath,
                outputPath = outputFile.absolutePath,
                targetHeight = targetHeight,
                targetBitrate = videoBitrate,
                progressCallback = progressCallback
            )

            val inputSize = inputFile.length()
            val outputSize = outputFile.length()
            val reduction = ((1 - outputSize.toFloat() / inputSize) * 100).toInt()

            Log.d(TAG, "✅ Compression complete!")
            Log.d(TAG, "Input: ${inputSize / 1024} KB")
            Log.d(TAG, "Output: ${outputSize / 1024} KB")
            Log.d(TAG, "Reduction: $reduction%")

            outputFile.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Compression failed", e)
            outputFile.delete()
            throw e
        }
    }

    /**
     * Real video compression using AndroidX Media3 Transformer
     * This re-encodes the video with lower resolution and bitrate
     * 
     * IMPORTANT: All Transformer operations must run on the Main thread
     */
    @UnstableApi
    private suspend fun compressWithTransformer(
        inputPath: String,
        outputPath: String,
        targetHeight: Int,
        targetBitrate: Int,
        progressCallback: ((Float) -> Unit)? = null
    ) = suspendCancellableCoroutine<Unit> { continuation ->
        
        // Move Transformer operations to Main thread
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val mediaItem = MediaItem.fromUri(Uri.fromFile(File(inputPath)))
                
                // Get video resolution and duration
                val mediaMetadataRetriever = MediaMetadataRetriever()
                mediaMetadataRetriever.setDataSource(inputPath)
                
                val originalWidth = mediaMetadataRetriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH
                )?.toIntOrNull() ?: 1920
                
                val originalHeight = mediaMetadataRetriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT
                )?.toIntOrNull() ?: 1080
                
                val durationMs = mediaMetadataRetriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_DURATION
                )?.toLongOrNull() ?: 0L
                
                mediaMetadataRetriever.release()
              // Safe scaling: only scale down, preserve aspect ratio,
// and let Media3 internally choose aligned dimensions.
val scale = if (originalHeight > targetHeight) {
    targetHeight.toFloat() / originalHeight.toFloat()
} else {
    1f
}

val scaledW = (originalWidth * scale).toInt()
val scaledH = (originalHeight * scale).toInt()

Log.d(TAG, "Scaled to: ${scaledW}x$scaledH")

// --- Align to 16px (prevents Samsung chroma smear) ---
val alignedW = (scaledW / 16) * 16
val alignedH = (scaledH / 16) * 16

Log.d(TAG, "Aligned dimensions: ${alignedW}x$alignedH")

// --- Pixel-space effect (forces GL composition) ---
val presentation = Presentation.createForWidthAndHeight(
    alignedW,
    alignedH,
    Presentation.LAYOUT_SCALE_TO_FIT_WITH_CROP
)

// --- Visual transform (scale only, no width override) ---
val scaleEffect = ScaleAndRotateTransformation.Builder()
    .setScale(scale, scale)
    .setRotationDegrees(0f)
    .build()

// 🔥 This is the final, correct Effects object
val effects = Effects(
    listOf(presentation),   // pixel-space effects
    listOf(scaleEffect)     // overlay transformation effects
)

val editedMediaItem = EditedMediaItem.Builder(mediaItem)
    .setEffects(effects)
    .setRemoveAudio(false)
    .setRemoveVideo(false)
    .build()


val videoEncoderSettings = VideoEncoderSettings.Builder()
    .setBitrate(targetBitrate)
    .build()

val encoderFactory = DefaultEncoderFactory.Builder(context)
    .setEnableFallback(true)
    .setRequestedVideoEncoderSettings(videoEncoderSettings) // ✅ CORRECT
    .build()

                
                Log.d(TAG, "Encoder configured with bitrate: ${targetBitrate / 1000} Kbps")

                // Build transformer
                val transformer = Transformer.Builder(context)
                    .setVideoMimeType(MimeTypes.VIDEO_H264)
                    .setEncoderFactory(encoderFactory)
                    .addListener(object : Transformer.Listener {
                        override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                            Log.d(TAG, "✅ Transformer completed")
                            Log.d(TAG, "Duration: ${exportResult.durationMs}ms")
                            Log.d(TAG, "Size: ${exportResult.fileSizeBytes / 1024}KB")
                            
                            progressCallback?.invoke(1.0f) // 100% complete
                            
                            if (continuation.isActive) {
                                continuation.resume(Unit)
                            }
                        }

                        override fun onError(
                            composition: Composition,
                            exportResult: ExportResult,
                            exportException: ExportException
                        ) {
                            Log.e(TAG, "❌ Transformer error", exportException)
                            
                            if (continuation.isActive) {
                                continuation.resumeWithException(
                                    IOException("Compression failed: ${exportException.message}", exportException)
                                )
                            }
                        }
                    })
                    .build()

                // Progress tracking using a coroutine (polling approach since Transformer doesn't provide progress)
                if (progressCallback != null && durationMs > 0) {
                    CoroutineScope(Dispatchers.IO).launch {
                        val startTime = System.currentTimeMillis()
                        while (continuation.isActive) {
                            try {
                                val outputFile = File(outputPath)
                                if (outputFile.exists()) {
                                    // Estimate progress based on file size growth
                                    // This is approximate but gives users feedback
                                    val elapsedTime = System.currentTimeMillis() - startTime
                                    val estimatedProgress = (elapsedTime.toFloat() / durationMs).coerceIn(0f, 0.95f)
                                    
                                    withContext(Dispatchers.Main) {
                                        progressCallback.invoke(estimatedProgress)
                                    }
                                }
                                kotlinx.coroutines.delay(500) // Update every 500ms
                            } catch (e: Exception) {
                                break
                            }
                        }
                    }
                }

                // Start transformation
                transformer.start(editedMediaItem, outputPath)
                
                Log.d(TAG, "🎬 Transformer started")

                // Handle cancellation
                continuation.invokeOnCancellation {
                    Log.d(TAG, "Compression cancelled")
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            transformer.cancel()
                        } catch (e: Exception) {
                            Log.e(TAG, "Error cancelling", e)
                        }
                    }
                }

            } catch (e: Exception) {
                Log.e(TAG, "Failed to start transformer", e)
                if (continuation.isActive) {
                    continuation.resumeWithException(e)
                }
            }
        }
    }

    // ============================================================================
    // HELPER METHODS
    // ============================================================================

    private fun createOutputFile(extension: String): File {
        val cacheDir = context.cacheDir
        val fileName = "compressed_${UUID.randomUUID()}.$extension"
        return File(cacheDir, fileName)
    }
}