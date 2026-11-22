import Flutter
import Speech

/// `memo/stt`: availability(locale), transcribeFile(path, locale) -> String, on device only. If the locale
/// has no on-device model it returns "" rather than send audio anywhere.
final class SttPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "memo/stt", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(SttPlugin(), channel: channel)
  }

  /// Held while a task runs: a released recogniser ends its task.
  private var active: SFSpeechRecognizer?

  /// A recogniser for [tag] that can run on device; nil otherwise.
  private func onDevice(_ tag: String?) -> SFSpeechRecognizer? {
    guard let r = SFSpeechRecognizer(locale: Locale(identifier: tag ?? "en-US")),
          r.isAvailable, r.supportsOnDeviceRecognition else { return nil }
    return r
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "available":
      result(onDevice(nil) != nil)
    case "availability":
      let tag = (call.arguments as? [String: Any])?["locale"] as? String
      result(onDevice(tag) != nil ? "installed" : "unavailable")
    case "transcribeFile":
      let args = call.arguments as? [String: Any]
      guard let path = args?["path"] as? String else { return result("") }
      let tag = args?["locale"] as? String
      SFSpeechRecognizer.requestAuthorization { status in
        guard status == .authorized, let recognizer = self.onDevice(tag) else {
          return DispatchQueue.main.async { result("") }
        }
        self.transcribe(URL(fileURLWithPath: path), recognizer, result)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func transcribe(_ url: URL, _ recognizer: SFSpeechRecognizer, _ result: @escaping FlutterResult) {
    active = recognizer
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
