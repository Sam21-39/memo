import Flutter
import Speech

/// `memo/stt`: transcribeFile(path) -> String, on device only. If the locale
/// has no on-device model it returns "" rather than send audio anywhere.
final class SttPlugin: NSObject, FlutterPlugin {
  private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "memo/stt", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(SttPlugin(), channel: channel)
  }

  private var available: Bool {
    recognizer?.isAvailable == true && recognizer?.supportsOnDeviceRecognition == true
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "available":
      result(available)
    case "transcribeFile":
      guard let path = (call.arguments as? [String: Any])?["path"] as? String else {
        return result("")
      }
      SFSpeechRecognizer.requestAuthorization { status in
        guard status == .authorized, self.available, let recognizer = self.recognizer else {
          return DispatchQueue.main.async { result("") }
        }
        self.transcribe(URL(fileURLWithPath: path), recognizer, result)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func transcribe(_ url: URL, _ recognizer: SFSpeechRecognizer, _ result: @escaping FlutterResult) {
    let request = SFSpeechURLRecognitionRequest(url: url)
    request.requiresOnDeviceRecognition = true
    request.shouldReportPartialResults = false
    var finished = false
    let finish: (String) -> Void = { text in
      DispatchQueue.main.async {
        if finished { return }
        finished = true
        result(text)
      }
    }
    let task = recognizer.recognitionTask(with: request) { response, error in
      if let response, response.isFinal {
        finish(response.bestTranscription.formattedString)
      } else if error != nil {
        finish("")
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
      task.cancel()
      finish("")
    }
  }
}
