import AVFoundation
import Flutter

/// `memo/tts` on iOS, the app's own voice, offline:
/// - render(text, gender, name, prefix) -> "<name>.caf": the Memō chime, the
///   reminder spoken, a pause, spoken again — one file in Library/Sounds an
///   alarm or notification can ring (under iOS's 30 s cap). Cached by name.
/// - preview(text, gender): speaks now.
/// - forget(prefix): deletes a removed reminder's renders.
final class TtsPlugin: NSObject, FlutterPlugin {
  private let synth = AVSpeechSynthesizer()
  private let speaker = AVSpeechSynthesizer()

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "memo/tts", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(TtsPlugin(), channel: channel)
  }

  private var sounds: URL {
    let dir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Sounds", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let gender = args["gender"] as? String ?? "female"
    switch call.method {
    case "render":
      guard let text = args["text"] as? String, let name = args["name"] as? String,
            let prefix = args["prefix"] as? String else { return result(nil) }
      let file = sounds.appendingPathComponent("\(name).caf")
      forget(prefix, except: file.lastPathComponent)
      if FileManager.default.fileExists(atPath: file.path) { return result(file.lastPathComponent) }
      render(text, gender: gender, to: file) { ok in result(ok ? file.lastPathComponent : nil) }
    case "preview":
      speaker.stopSpeaking(at: .immediate)
      speaker.speak(utterance(args["text"] as? String ?? "", gender: gender))
      result(nil)
    case "forget":
      forget(args["prefix"] as? String ?? "\u{0}", except: nil)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func forget(_ prefix: String, except keep: String?) {
    let names = (try? FileManager.default.contentsOfDirectory(atPath: sounds.path)) ?? []
    for name in names where name.hasPrefix(prefix) && name != keep {
      try? FileManager.default.removeItem(at: sounds.appendingPathComponent(name))
    }
  }

  /// An installed English voice of the asked gender, the phone's own region
  /// first, best quality first. Falls back to the default voice, pitched.
  private func utterance(_ text: String, gender: String) -> AVSpeechUtterance {
    let u = AVSpeechUtterance(string: text)
    let want: AVSpeechSynthesisVoiceGender = gender == "male" ? .male : .female
    let region = Locale.current.region?.identifier ?? "US"
    let voices = AVSpeechSynthesisVoice.speechVoices()
      .filter { $0.language.hasPrefix("en") && $0.gender == want }
      .sorted {
        let a = ($0.language.hasSuffix(region) ? 10 : 0) + $0.quality.rawValue
        let b = ($1.language.hasSuffix(region) ? 10 : 0) + $1.quality.rawValue
        return a > b
      }
    if let voice = voices.first {
      u.voice = voice
    } else {
      u.voice = AVSpeechSynthesisVoice(language: "en-US")
      u.pitchMultiplier = gender == "male" ? 0.8 : 1.15
    }
    u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
    return u
  }

  private func render(_ text: String, gender: String, to file: URL, done: @escaping (Bool) -> Void) {
    guard let chimeURL = Bundle.main.url(forResource: "memo_ring", withExtension: "caf"),
          let chime = try? AVAudioFile(forReading: chimeURL) else { return done(false) }
    let format = chime.processingFormat
    var speech: [AVAudioPCMBuffer] = []
    var finished = false
    synth.write(utterance(text, gender: gender)) { buffer in
      guard !finished, let pcm = buffer as? AVAudioPCMBuffer else { return }
      if pcm.frameLength == 0 {
        finished = true
        DispatchQueue.main.async {
          done(Self.compose(chime: chime, speech: speech, format: format, to: file))
        }
      } else {
        speech.append(pcm)
      }
    }
  }

  /// chime · speech · 0.6 s · speech, converted to the chime's format,
  /// capped below 30 s.
  private static func compose(
    chime: AVAudioFile, speech: [AVAudioPCMBuffer], format: AVAudioFormat, to file: URL
  ) -> Bool {
    guard let first = speech.first,
          let converter = AVAudioConverter(from: first.format, to: format),
          let out = try? AVAudioFile(forWriting: file, settings: chime.fileFormat.settings,
                                     commonFormat: format.commonFormat, interleaved: format.isInterleaved)
    else { return false }
    let cap = AVAudioFramePosition(format.sampleRate * 29)
    func write(_ buffer: AVAudioPCMBuffer) {
      let room = cap - out.length
      guard room > 0 else { return }
      buffer.frameLength = min(buffer.frameLength, AVAudioFrameCount(room))
      try? out.write(from: buffer)
    }
    // Chime.
    chime.framePosition = 0
    if let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(chime.length)) {
      try? chime.read(into: buf)
      write(buf)
    }
    // Speech, converted once, written twice around a short pause.
    var converted: [AVAudioPCMBuffer] = []
    for input in speech {
      let ratio = format.sampleRate / input.format.sampleRate
      guard let buf = AVAudioPCMBuffer(
        pcmFormat: format, frameCapacity: AVAudioFrameCount(Double(input.frameLength) * ratio) + 1024
      ) else { continue }
      var fed = false
      converter.convert(to: buf, error: nil) { _, status in
        if fed { status.pointee = .noDataNow; return nil }
        fed = true
        status.pointee = .haveData
        return input
      }
      converted.append(buf)
    }
    let pause = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(format.sampleRate * 0.6))!
    pause.frameLength = pause.frameCapacity
    if let data = pause.floatChannelData {
      for ch in 0..<Int(format.channelCount) {
        data[ch].update(repeating: 0, count: Int(pause.frameLength))
      }
    } else if let data = pause.int16ChannelData {
      for ch in 0..<Int(format.channelCount) {
        data[ch].update(repeating: 0, count: Int(pause.frameLength))
      }
    }
    for buf in converted { write(buf.copy() as! AVAudioPCMBuffer) }
    write(pause)
    for buf in converted { write(buf.copy() as! AVAudioPCMBuffer) }
    return out.length > 0
  }
}
