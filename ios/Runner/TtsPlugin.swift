import AVFoundation
import Flutter

/// `memo/tts` on iOS, the app's own voice, offline:
/// - render(text, gender, language, name) -> "<name>.caf": the Memō chime, the
///   reminder spoken, a pause, spoken again — one file in Library/Sounds an
///   alarm or notification can ring (under iOS's 30 s cap). Cached by name;
///   written as "<name>.tmp.caf" (AVAudioFile picks the file type from
///   the extension, so it stays .caf) and moved into place. nil when no installed
///   voice speaks the language (never another language's voice).
/// - preview(text, gender, language) -> Bool: speaks now.
/// - voices() -> languages among en/hi/bn with an installed voice.
/// - prune(prefix, keep): deletes a reminder's older renders, after its alarm
///   was re-registered.
/// - forget(prefix): deletes a removed reminder's renders.
final class TtsPlugin: NSObject, FlutterPlugin {
  private let synth = AVSpeechSynthesizer()
  private let speaker = AVSpeechSynthesizer()

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "memo/tts", binaryMessenger: registrar.messenger())
    let plugin = TtsPlugin()
    plugin.removeStrayTemps()
    registrar.addMethodCallDelegate(plugin, channel: channel)
  }

  private static let tempSuffix = ".tmp.caf"

  /// A kill mid-render leaves a partial temp file: never a sound.
  func removeStrayTemps() {
    let names = (try? FileManager.default.contentsOfDirectory(atPath: sounds.path)) ?? []
    for name in names where name.hasSuffix(Self.tempSuffix) {
      try? FileManager.default.removeItem(at: sounds.appendingPathComponent(name))
    }
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
    let language = args["language"] as? String ?? "en"
    switch call.method {
    case "render":
      guard let text = args["text"] as? String, let name = args["name"] as? String,
            let u = utterance(text, gender: gender, language: language) else { return result(nil) }
      let file = sounds.appendingPathComponent("\(name).caf")
      if FileManager.default.fileExists(atPath: file.path) { return result(file.lastPathComponent) }
      render(u, to: file) { ok in result(ok ? file.lastPathComponent : nil) }
    case "preview":
      guard let u = utterance(args["text"] as? String ?? "", gender: gender, language: language) else {
        return result(false)
      }
      speaker.stopSpeaking(at: .immediate)
      speaker.speak(u)
      result(true)
    case "voices":
      let all = AVSpeechSynthesisVoice.speechVoices()
      result(["en", "hi", "bn"].filter { l in all.contains { $0.language.hasPrefix(l) } })
    case "prune":
      forget(args["prefix"] as? String ?? "\u{0}", except: args["keep"] as? String)
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
    for name in names where name.hasPrefix(prefix) && name != keep && !name.hasSuffix(Self.tempSuffix) {
      try? FileManager.default.removeItem(at: sounds.appendingPathComponent(name))
    }
  }

  /// An installed voice of [language] (preferred gender, then any), the
  /// phone's own region first, best quality first. Nil when there is none: a
  /// Bengali or Hindi text is never read by another language's voice. English
  /// falls back to the default voice, pitched.
  private func utterance(_ text: String, gender: String, language: String) -> AVSpeechUtterance? {
    let u = AVSpeechUtterance(string: text)
    let want: AVSpeechSynthesisVoiceGender = gender == "male" ? .male : .female
    let region = Locale.current.region?.identifier ?? "US"
    let installed = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(language) }
    func ranked(_ list: [AVSpeechSynthesisVoice]) -> [AVSpeechSynthesisVoice] {
      list.sorted {
        let a = ($0.language.hasSuffix(region) ? 10 : 0) + $0.quality.rawValue
        let b = ($1.language.hasSuffix(region) ? 10 : 0) + $1.quality.rawValue
        return a > b
      }
    }
    if let voice = ranked(installed.filter { $0.gender == want }).first ?? ranked(installed).first {
      u.voice = voice
      // Only English promises a gender; others keep the voice as it is.
      if language == "en", voice.gender != want { u.pitchMultiplier = gender == "male" ? 0.8 : 1.15 }
    } else if language == "en" {
      u.voice = AVSpeechSynthesisVoice(language: "en-US")
      u.pitchMultiplier = gender == "male" ? 0.8 : 1.15
    } else {
      return nil
    }
    u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
    return u
  }

  /// Composes into "<name>.tmp.caf", then moves it into place.
  private func render(_ utterance: AVSpeechUtterance, to file: URL, done: @escaping (Bool) -> Void) {
    let tmp = file.deletingLastPathComponent().appendingPathComponent(
      file.deletingPathExtension().lastPathComponent + Self.tempSuffix)
    try? FileManager.default.removeItem(at: tmp)
    synthesize(utterance, to: tmp) { ok in
      let fm = FileManager.default
      let moved = ok && (try? fm.moveItem(at: tmp, to: file)) != nil
      // Nothing moved: drop the temp. A file already in place (an earlier
      // render of the same name) still counts as done.
      if !moved { try? fm.removeItem(at: tmp) }
      done(moved || (ok && fm.fileExists(atPath: file.path)))
    }
  }

  private func synthesize(_ utterance: AVSpeechUtterance, to file: URL, done: @escaping (Bool) -> Void) {
    guard let chimeURL = Bundle.main.url(forResource: "memo_ring", withExtension: "caf"),
          let chime = try? AVAudioFile(forReading: chimeURL) else { return done(false) }
    let format = chime.processingFormat
    var speech: [AVAudioPCMBuffer] = []
    var finished = false
    synth.write(utterance) { buffer in
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
