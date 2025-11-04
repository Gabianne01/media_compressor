package io.github.harikrishnan_cr.media_compressor

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import kotlin.math.min

class MediaCompressorPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var eventSink: EventChannel.EventSink? = null
    private var compressionJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.IO)

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "media_compressor")
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "media_compressor/progress")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "compressImage" -> {
                val path = call.argument<String>("path")
                val quality = call.argument<Int>("quality")
                
                if (path == null || quality == null) {
                    result.error("INVALID_ARGUMENTS", "Path and quality are required", null)
                    return
                }
                
                scope.launch {
                    try {
                        val compressedPath = compressImage(path, quality)
                        withContext(Dispatchers.Main) {
                            result.success(compressedPath)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("COMPRESSION_ERROR", e.message, null)
                        }
                    }
                }
            }
            
            "compressImageWithOptions" -> {
                val path = call.argument<String>("path")
                val options = call.argument<Map<String, Any>>("options")
                
                if (path == null || options == null) {
                    result.error("INVALID_ARGUMENTS", "Path and options are required", null)
                    return
                }
                
                scope.launch {
                    try {
                        val compressedResult = compressImageWithOptions(path, options)
                        withContext(Dispatchers.Main) {
                            result.success(compressedResult)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("COMPRESSION_ERROR", e.message, null)
                        }
                    }
                }
            }
            
            "compressVideo" -> {
                val path = call.argument<String>("path")
                val quality = call.argument<String>("quality")
                
                if (path == null || quality == null) {
                    result.error("INVALID_ARGUMENTS", "Path and quality are required", null)
                    return
                }
                
                compressionJob = scope.launch {
                    try {
                        val compressedPath = compressVideo(path, quality)
                        withContext(Dispatchers.Main) {
                            result.success(compressedPath)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("COMPRESSION_ERROR", e.message, null)
                        }
                    }
                }
            }
            
            "compressVideoWithOptions" -> {
                val path = call.argument<String>("path")
                val options = call.argument<Map<String, Any>>("options")
                
                if (path == null || options == null) {
                    result.error("INVALID_ARGUMENTS", "Path and options are required", null)
                    return
                }
                
                compressionJob = scope.launch {
                    try {
                        val compressedResult = compressVideoWithOptions(path, options)
                        withContext(Dispatchers.Main) {
                            result.success(compressedResult)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("COMPRESSION_ERROR", e.message, null)
                        }
                    }
                }
            }
            
            "cancelCompression" -> {
                compressionJob?.cancel()
                result.success(null)
            }
            
            "getSupportedImageFormats" -> {
                result.success(listOf("jpeg", "png", "webp"))
            }
            
            "getSupportedVideoFormats" -> {
                result.success(listOf("mp4", "3gp", "webm"))
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }

    private suspend fun compressImage(path: String, quality: Int): String {
        return withContext(Dispatchers.IO) {
            val inputFile = File(path)
            val outputFile = File(context.cacheDir, "compressed_${System.currentTimeMillis()}.jpg")
            
            val bitmap = BitmapFactory.decodeFile(path)
            val outputStream = FileOutputStream(outputFile)
            
            bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
            outputStream.close()
            bitmap.recycle()
            
            outputFile.absolutePath
        }
    }

    private suspend fun compressImageWithOptions(
        path: String,
        options: Map<String, Any>
    ): Map<String, Any> {
        return withContext(Dispatchers.IO) {
            val inputFile = File(path)
            val originalSize = inputFile.length()
            
            val quality = options["quality"] as? Int ?: 80
            val maxWidth = options["maxWidth"] as? Int
            val maxHeight = options["maxHeight"] as? Int
            val format = options["format"] as? String ?: "jpeg"
            
            val outputFile = File(
                context.cacheDir,
                "compressed_${System.currentTimeMillis()}.${getExtension(format)}"
            )
            
            // Load and scale bitmap
            val bmOptions = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(path, bmOptions)
            
            val scaleFactor = calculateScaleFactor(
                bmOptions.outWidth,
                bmOptions.outHeight,
                maxWidth,
                maxHeight
            )
            
            bmOptions.inJustDecodeBounds = false
            bmOptions.inSampleSize = scaleFactor
            
            val bitmap = BitmapFactory.decodeFile(path, bmOptions)
            
            // Compress with specified format
            val outputStream = FileOutputStream(outputFile)
            val compressFormat = when (format) {
                "png" -> Bitmap.CompressFormat.PNG
                "webp" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    Bitmap.CompressFormat.WEBP_LOSSLESS
                } else {
                    @Suppress("DEPRECATION")
                    Bitmap.CompressFormat.WEBP
                }
                else -> Bitmap.CompressFormat.JPEG
            }
            
            bitmap.compress(compressFormat, quality, outputStream)
            outputStream.close()
            bitmap.recycle()
            
            val compressedSize = outputFile.length()
            
            mapOf(
                "path" to outputFile.absolutePath,
                "originalSize" to originalSize.toInt(),
                "compressedSize" to compressedSize.toInt(),
                "compressionRatio" to (compressedSize.toDouble() / originalSize.toDouble())
            )
        }
    }

    private suspend fun compressVideo(path: String, quality: String): String {
        return withContext(Dispatchers.IO) {
            val outputPath = File(
                context.cacheDir,
                "compressed_${System.currentTimeMillis()}.mp4"
            ).absolutePath
            
            val bitrate = when (quality) {
                "veryLow" -> 500000
                "low" -> 1000000
                "medium" -> 2000000
                "high" -> 4000000
                "veryHigh" -> 8000000
                else -> 2000000
            }
            
            compressVideoInternal(path, outputPath, bitrate)
            outputPath
        }
    }

    private suspend fun compressVideoWithOptions(
        path: String,
        options: Map<String, Any>
    ): Map<String, Any> {
        return withContext(Dispatchers.IO) {
            val inputFile = File(path)
            val originalSize = inputFile.length()
            
            val outputPath = File(
                context.cacheDir,
                "compressed_${System.currentTimeMillis()}.mp4"
            ).absolutePath
            
            val bitrate = options["bitrate"] as? Int ?: 2000000
            
            val startTime = System.currentTimeMillis()
            compressVideoInternal(path, outputPath, bitrate)
            val duration = System.currentTimeMillis() - startTime
            
            val outputFile = File(outputPath)
            val compressedSize = outputFile.length()
            
            mapOf(
                "path" to outputPath,
                "originalSize" to originalSize.toInt(),
                "compressedSize" to compressedSize.toInt(),
                "compressionRatio" to (compressedSize.toDouble() / originalSize.toDouble()),
                "duration" to duration.toInt()
            )
        }
    }

    @Suppress("DEPRECATION")
    private fun compressVideoInternal(inputPath: String, outputPath: String, bitrate: Int) {
        val extractor = MediaExtractor()
        extractor.setDataSource(inputPath)
        
        val trackCount = extractor.trackCount
        var videoTrackIndex = -1
        
        for (i in 0 until trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("video/") == true) {
                videoTrackIndex = i
                break
            }
        }
        
        if (videoTrackIndex == -1) {
            throw IllegalArgumentException("No video track found")
        }
        
        extractor.selectTrack(videoTrackIndex)
        val inputFormat = extractor.getTrackFormat(videoTrackIndex)
        
        // Configure output format
        val outputFormat = MediaFormat.createVideoFormat(
            MediaFormat.MIMETYPE_VIDEO_AVC,
            inputFormat.getInteger(MediaFormat.KEY_WIDTH),
            inputFormat.getInteger(MediaFormat.KEY_HEIGHT)
        ).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, 30)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }
        
        // Simple copy for demonstration - in production, use MediaCodec for transcoding
        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val trackIndex = muxer.addTrack(inputFormat)
        muxer.start()
        
        val buffer = ByteBuffer.allocate(1024 * 1024)
        val bufferInfo = MediaCodec.BufferInfo()
        
        var totalBytesWritten = 0L
        while (true) {
            val sampleSize = extractor.readSampleData(buffer, 0)
            if (sampleSize < 0) break
            
            bufferInfo.offset = 0
            bufferInfo.size = sampleSize
            bufferInfo.presentationTimeUs = extractor.sampleTime
            bufferInfo.flags = extractor.sampleFlags
            
            muxer.writeSampleData(trackIndex, buffer, bufferInfo)
            
            totalBytesWritten += sampleSize
            
            // Report progress
            eventSink?.let { sink ->
                val progress = (totalBytesWritten.toDouble() / inputFormat.getLong(MediaFormat.KEY_DURATION)) * 100
                sink.success(min(progress, 100.0))
            }
            
            extractor.advance()
        }
        
        muxer.stop()
        muxer.release()
        extractor.release()
    }

    private fun calculateScaleFactor(
        width: Int,
        height: Int,
        maxWidth: Int?,
        maxHeight: Int?
    ): Int {
        var scaleFactor = 1
        
        if (maxWidth != null && maxHeight != null) {
            while ((width / scaleFactor) > maxWidth || (height / scaleFactor) > maxHeight) {
                scaleFactor *= 2
            }
        }
        
        return scaleFactor
    }

    private fun getExtension(format: String): String {
        return when (format) {
            "png" -> "png"
            "webp" -> "webp"
            else -> "jpg"
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        scope.cancel()
    }
}