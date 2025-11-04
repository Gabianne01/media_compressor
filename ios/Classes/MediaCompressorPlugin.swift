import Flutter
import UIKit
import AVFoundation
import Photos

public class MediaCompressorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var compressionTask: AVAssetExportSession?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "media_compressor", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "media_compressor/progress", binaryMessenger: registrar.messenger())
        
        let instance = MediaCompressorPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "compressImage":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String,
                  let quality = args["quality"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", 
                                  message: "Path and quality are required", 
                                  details: nil))
                return
            }
            
            compressImage(path: path, quality: quality) { compressedPath, error in
                if let error = error {
                    result(FlutterError(code: "COMPRESSION_ERROR", 
                                      message: error.localizedDescription, 
                                      details: nil))
                } else {
                    result(compressedPath)
                }
            }
            
        case "compressImageWithOptions":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String,
                  let options = args["options"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", 
                                  message: "Path and options are required", 
                                  details: nil))
                return
            }
            
            compressImageWithOptions(path: path, options: options) { compressionResult, error in
                if let error = error {
                    result(FlutterError(code: "COMPRESSION_ERROR", 
                                      message: error.localizedDescription, 
                                      details: nil))
                } else {
                    result(compressionResult)
                }
            }
            
        case "compressVideo":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String,
                  let quality = args["quality"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", 
                                  message: "Path and quality are required", 
                                  details: nil))
                return
            }
            
            compressVideo(path: path, quality: quality) { compressedPath, error in
                if let error = error {
                    result(FlutterError(code: "COMPRESSION_ERROR", 
                                      message: error.localizedDescription, 
                                      details: nil))
                } else {
                    result(compressedPath)
                }
            }
            
        case "compressVideoWithOptions":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String,
                  let options = args["options"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", 
                                  message: "Path and options are required", 
                                  details: nil))
                return
            }
            
            compressVideoWithOptions(path: path, options: options) { compressionResult, error in
                if let error = error {
                    result(FlutterError(code: "COMPRESSION_ERROR", 
                                      message: error.localizedDescription, 
                                      details: nil))
                } else {
                    result(compressionResult)
                }
            }
            
        case "cancelCompression":
            compressionTask?.cancelExport()
            result(nil)
            
        case "getSupportedImageFormats":
            result(["jpeg", "png", "heic"])
            
        case "getSupportedVideoFormats":
            result(["mp4", "mov", "m4v"])
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func compressImage(path: String, quality: Int, completion: @escaping (String?, Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let url = URL(fileURLWithPath: path)
            
            guard let image = UIImage(contentsOfFile: path) else {
                completion(nil, NSError(domain: "MediaCompressor", code: 1, 
                                       userInfo: [NSLocalizedDescriptionKey: "Failed to load image"]))
                return
            }
            
            let compressionQuality = CGFloat(quality) / 100.0
            guard let data = image.jpegData(compressionQuality: compressionQuality) else {
                completion(nil, NSError(domain: "MediaCompressor", code: 2, 
                                       userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"]))
                return
            }
            
            let outputURL = self.getOutputURL(extension: "jpg")
            
            do {
                try data.write(to: outputURL)
                completion(outputURL.path, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    private func compressImageWithOptions(path: String, options: [String: Any], 
                                         completion: @escaping ([String: Any]?, Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let url = URL(fileURLWithPath: path)
            let originalSize = self.getFileSize(at: url)
            
            guard let image = UIImage(contentsOfFile: path) else {
                completion(nil, NSError(domain: "MediaCompressor", code: 1, 
                                       userInfo: [NSLocalizedDescriptionKey: "Failed to load image"]))
                return
            }
            
            let quality = options["quality"] as? Int ?? 80
            let maxWidth = options["maxWidth"] as? Int
            let maxHeight = options["maxHeight"] as? Int
            let format = options["format"] as? String ?? "jpeg"
            
            // Resize if needed
            let resizedImage: UIImage
            if let maxW = maxWidth, let maxH = maxHeight {
                resizedImage = self.resizeImage(image, maxWidth: CGFloat(maxW), maxHeight: CGFloat(maxH))
            } else {
                resizedImage = image
            }
            
            // Compress based on format
            let compressionQuality = CGFloat(quality) / 100.0
            let imageData: Data?
            let fileExtension: String
            
            switch format {
            case "png":
                imageData = resizedImage.pngData()
                fileExtension = "png"
            case "heic":
                if #available(iOS 11.0, *) {
                    imageData = resizedImage.heicData(compressionQuality: compressionQuality)
                    fileExtension = "heic"
                } else {
                    imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
                    fileExtension = "jpg"
                }
            default:
                imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
                fileExtension = "jpg"
            }
            
            guard let data = imageData else {
                completion(nil, NSError(domain: "MediaCompressor", code: 2, 
                                       userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"]))
                return
            }
            
            let outputURL = self.getOutputURL(extension: fileExtension)
            
            do {
                try data.write(to: outputURL)
                let compressedSize = data.count
                
                let result: [String: Any] = [
                    "path": outputURL.path,
                    "originalSize": originalSize,
                    "compressedSize": compressedSize,
                    "compressionRatio": Double(compressedSize) / Double(originalSize)
                ]
                
                completion(result, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    private func compressVideo(path: String, quality: String, 
                              completion: @escaping (String?, Error?) -> Void) {
        let inputURL = URL(fileURLWithPath: path)
        let outputURL = getOutputURL(extension: "mp4")
        
        let presetName: String
        switch quality {
        case "veryLow":
            presetName = AVAssetExportPresetLowQuality
        case "low":
            presetName = AVAssetExportPresetMediumQuality
        case "medium":
            presetName = AVAssetExportPresetHighestQuality
        case "high":
            presetName = AVAssetExportPreset1920x1080
        case "veryHigh":
            presetName = AVAssetExportPreset3840x2160
        default:
            presetName = AVAssetExportPresetHighestQuality
        }
        
        compressVideoInternal(inputURL: inputURL, outputURL: outputURL, 
                            preset: presetName, completion: completion)
    }
    
    private func compressVideoWithOptions(path: String, options: [String: Any], 
                                         completion: @escaping ([String: Any]?, Error?) -> Void) {
        let inputURL = URL(fileURLWithPath: path)
        let outputURL = getOutputURL(extension: "mp4")
        let originalSize = getFileSize(at: inputURL)
        
        let quality = options["quality"] as? String ?? "medium"
        let presetName: String
        
        switch quality {
        case "veryLow":
            presetName = AVAssetExportPresetLowQuality
        case "low":
            presetName = AVAssetExportPresetMediumQuality
        case "medium":
            presetName = AVAssetExportPresetHighestQuality
        case "high":
            presetName = AVAssetExportPreset1920x1080
        case "veryHigh":
            presetName = AVAssetExportPreset3840x2160
        default:
            presetName = AVAssetExportPresetHighestQuality
        }
        
        let startTime = Date()
        
        compressVideoInternal(inputURL: inputURL, outputURL: outputURL, preset: presetName) { path, error in
            if let error = error {
                completion(nil, error)
            } else if let path = path {
                let compressedSize = self.getFileSize(at: URL(fileURLWithPath: path))
                let duration = Int(Date().timeIntervalSince(startTime) * 1000)
                
                let result: [String: Any] = [
                    "path": path,
                    "originalSize": originalSize,
                    "compressedSize": compressedSize,
                    "compressionRatio": Double(compressedSize) / Double(originalSize),
                    "duration": duration
                ]
                
                completion(result, nil)
            }
        }
    }
    
    private func compressVideoInternal(inputURL: URL, outputURL: URL, preset: String, 
                                      completion: @escaping (String?, Error?) -> Void) {
        let asset = AVAsset(url: inputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            completion(nil, NSError(domain: "MediaCompressor", code: 3, 
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"]))
            return
        }
        
        compressionTask = exportSession
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Set up progress monitoring
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let progress = exportSession.progress
            self.eventSink?(Double(progress * 100))
        }
        
        exportSession.exportAsynchronously {
            progressTimer.invalidate()
            
            switch exportSession.status {
            case .completed:
                completion(outputURL.path, nil)
            case .failed:
                completion(nil, exportSession.error)
            case .cancelled:
                completion(nil, NSError(domain: "MediaCompressor", code: 4, 
                                      userInfo: [NSLocalizedDescriptionKey: "Compression cancelled"]))
            default:
                completion(nil, NSError(domain: "MediaCompressor", code: 5, 
                                      userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let size = image.size
        let widthRatio = maxWidth / size.width
        let heightRatio = maxHeight / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func getOutputURL(extension ext: String) -> URL {
        let tempDir = NSTemporaryDirectory()
        let fileName = "compressed_\(Date().timeIntervalSince1970).\(ext)"
        return URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)
    }
    
    private func getFileSize(at url: URL) -> Int {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int ?? 0
        } catch {
            return 0
        }
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

// MARK: - UIImage Extension for HEIC

@available(iOS 11.0, *)
extension UIImage {
    func heicData(compressionQuality: CGFloat) -> Data? {
        let data = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(
            data, AVFileType.heic as CFString, 1, nil
        ) else { return nil }
        
        guard let cgImage = self.cgImage else { return nil }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        
        CGImageDestinationAddImage(imageDestination, cgImage, options as CFDictionary)
        CGImageDestinationFinalize(imageDestination)
        
        return data as Data
    }
}