import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Text recognition for slips: the path in, the recognised text out.
    // Errors carry only a code, never the text or the path.
    let channel = FlutterMethodChannel(
      name: "moneylens/ocr",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognize" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
        result(FlutterError(code: "bad_arguments", message: nil, details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let outcome = SlipOcr.recognize(path: path)
        DispatchQueue.main.async {
          switch outcome {
          case .success(let text): result(text)
          case .failure(let error): result(FlutterError(code: error.code, message: nil, details: nil))
          }
        }
      }
    }
  }
}

/// Reads the text of a payment slip with Apple Vision (Thai + English).
/// Thai recognition needs iOS 16; earlier versions report `ocr_unavailable`.
enum SlipOcr {
  struct Failure: Error { let code: String }

  static func recognize(path: String) -> Result<String, Failure> {
    guard #available(iOS 16.0, *) else { return .failure(Failure(code: "ocr_unavailable")) }
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      return .failure(Failure(code: "unreadable_image"))
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    request.recognitionLanguages = ["th-TH", "en-US"]
    let orientation = CGImagePropertyOrientation(image.imageOrientation)
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
    do {
      try handler.perform([request])
    } catch {
      return .failure(Failure(code: "ocr_failed"))
    }
    // Top to bottom, so the text reads like the slip does.
    let lines = (request.results ?? [])
      .sorted { $0.boundingBox.midY > $1.boundingBox.midY }
      .compactMap { $0.topCandidates(1).first?.string }
    return .success(lines.joined(separator: "\n"))
  }
}

private extension CGImagePropertyOrientation {
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
