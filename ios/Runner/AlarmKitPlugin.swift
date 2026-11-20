import ActivityKit
import AlarmKit
import AppIntents
import Flutter
import SwiftUI

/// `memo/alarmkit`: real alarms on iOS 26+. Full screen over the lock screen,
/// through silent mode and Focus, Done and Snooze on the alert — the way the
/// Clock app rings. Dart computes the fires; this registers one AlarmKit alarm
/// per fire and remembers which belong to which reminder.
///
/// Done / Snooze run as App Intents without opening the app: they quiet this
/// occurrence's one-off alarms (nags), a snooze arms its own alarm 10 min out,
/// and both are queued for Dart to apply to the database on next open.
final class AlarmKitPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "memo/alarmkit", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(AlarmKitPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 26.0, *) else {
      return call.method == "status" ? result("unavailable") : result(FlutterMethodNotImplemented)
    }
    let args = call.arguments as? [String: Any] ?? [:]
    Task { @MainActor in
      do {
        switch call.method {
        case "status":
          result(MemoAlarms.status())
        case "authorize":
          result(try await MemoAlarms.authorize())
        case "schedule":
          try await MemoAlarms.schedule(
            reminderId: args["reminderId"] as! String,
            fires: MemoAlarms.decode(args["fires"] as! String))
          result(nil)
        case "cancel":
          MemoAlarms.cancel(reminderId: args["reminderId"] as! String)
          result(nil)
        case "replaceAll":
          try await MemoAlarms.replaceAll(MemoAlarms.decode(args["fires"] as! String))
          result(nil)
        case "drainActions":
          result(MemoAlarms.drainActions())
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(code: "alarmkit", message: "\(error)", details: nil))
      }
    }
  }
}

@available(iOS 26.0, *)
struct MemoAlarmMetadata: AlarmMetadata {
  var reminderId: String
}

/// One fire from Dart.
struct MemoFire: Codable {
  var id: Int
  var at: Double  // epoch ms, local wall time already resolved
  var `repeat`: String  // none | daily | weekly
  var kind: String
  var reminderId: String
  var title: String
  var sound: String?
  var snoozeId: Int
  var doneLabel: String?
  var snoozeLabel: String?
}

@available(iOS 26.0, *)
enum MemoAlarms {
  static let defaults = UserDefaults.standard
  /// reminderId -> [fireId: isOneOff]
  static let mapKey = "memo.alarmkit.map"
  static let queueKey = "memo.alarmkit.actions"
  static let doneKey = "memo.alarmkit.done"
  static let snoozeKey = "memo.alarmkit.snooze"

  static func status() -> String {
    switch AlarmManager.shared.authorizationState {
    case .authorized: return "authorized"
    case .denied: return "denied"
    default: return "notDetermined"
    }
  }

  static func authorize() async throws -> Bool {
    try await AlarmManager.shared.requestAuthorization() == .authorized
  }

  static func decode(_ json: String) throws -> [MemoFire] {
    try JSONDecoder().decode([MemoFire].self, from: Data(json.utf8))
  }

  /// Stable UUID per fire id, so cancel finds what schedule registered.
  static func uuid(_ fireId: Int) -> UUID {
    UUID(uuidString: String(format: "4D454D4F-0000-4000-8000-%012llX", UInt64(UInt32(truncatingIfNeeded: fireId))))!
  }

  static var map: [String: [String: Bool]] {
    get { defaults.dictionary(forKey: mapKey) as? [String: [String: Bool]] ?? [:] }
    set { defaults.set(newValue, forKey: mapKey) }
  }

  static func cancel(reminderId: String, oneOffOnly: Bool = false) {
    var all = map
    var mine = all[reminderId] ?? [:]
    for (fire, oneOff) in mine where !oneOffOnly || oneOff {
      try? AlarmManager.shared.cancel(id: uuid(Int(fire)!))
      mine.removeValue(forKey: fire)
    }
    all[reminderId] = mine.isEmpty ? nil : mine
    map = all
  }

  static func schedule(reminderId: String, fires: [MemoFire]) async throws {
    cancel(reminderId: reminderId)
    for fire in fires { try await add(fire) }
  }

  static func replaceAll(_ fires: [MemoFire]) async throws {
    for reminderId in map.keys { cancel(reminderId: reminderId) }
    for fire in fires { try await add(fire) }
  }

  static func add(_ fire: MemoFire) async throws {
    let at = Date(timeIntervalSince1970: fire.at / 1000)
    let parts = Calendar.current.dateComponents([.hour, .minute, .weekday], from: at)
    let time = Alarm.Schedule.Relative.Time(hour: parts.hour!, minute: parts.minute!)
    let schedule: Alarm.Schedule = switch fire.`repeat` {
    case "daily":
      .relative(.init(time: time, repeats: .weekly([.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday])))
    case "weekly":
      .relative(.init(time: time, repeats: .weekly([weekday(parts.weekday!)])))
    default:
      .fixed(at)
    }
    // Labels come from Dart in the interface language; a re-armed snooze
    // carries none and reads the ones stored at the last schedule.
    if let label = fire.doneLabel { defaults.set(label, forKey: doneKey) }
    if let label = fire.snoozeLabel { defaults.set(label, forKey: snoozeKey) }
    let done = fire.doneLabel ?? defaults.string(forKey: doneKey) ?? "Done"
    let snooze = fire.snoozeLabel ?? defaults.string(forKey: snoozeKey) ?? "Snooze 10 minutes"
    let alert = AlarmPresentation.Alert(
      title: LocalizedStringResource(String.LocalizationValue(fire.title), table: "Verbatim"),
      stopButton: AlarmButton(text: LocalizedStringResource(String.LocalizationValue(done), table: "Verbatim"), textColor: .white, systemImageName: "checkmark"),
      secondaryButton: AlarmButton(text: LocalizedStringResource(String.LocalizationValue(snooze), table: "Verbatim"), textColor: .white, systemImageName: "zzz"),
      secondaryButtonBehavior: .custom)
    let attributes = AlarmAttributes(
      presentation: AlarmPresentation(alert: alert),
      metadata: MemoAlarmMetadata(reminderId: fire.reminderId),
      tintColor: Color(red: 1, green: 0.353, blue: 0.373))
    let config = AlarmManager.AlarmConfiguration(
      schedule: schedule,
      attributes: attributes,
      stopIntent: MemoDoneIntent(reminderId: fire.reminderId),
      secondaryIntent: MemoSnoozeIntent(
        reminderId: fire.reminderId, title: fire.title, sound: fire.sound ?? "", snoozeId: fire.snoozeId),
      sound: fire.sound.map { .named($0) } ?? .named("memo_ring.caf"))
    _ = try await AlarmManager.shared.schedule(id: uuid(fire.id), configuration: config)
    var all = map
    all[fire.reminderId, default: [:]][String(fire.id)] = fire.`repeat` == "none"
    map = all
  }

  /// DateComponents weekday: Sunday = 1.
  static func weekday(_ n: Int) -> Locale.Weekday {
    [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday][(n - 1) % 7]
  }

  static func enqueue(_ reminderId: String, _ action: String) {
    var queue = defaults.array(forKey: queueKey) as? [[String: Any]] ?? []
    queue.append(["reminderId": reminderId, "action": action, "at": Date().timeIntervalSince1970 * 1000])
    defaults.set(queue, forKey: queueKey)
  }

  static func drainActions() -> String {
    let queue = defaults.array(forKey: queueKey) as? [[String: Any]] ?? []
    defaults.removeObject(forKey: queueKey)
    let data = (try? JSONSerialization.data(withJSONObject: queue)) ?? Data("[]".utf8)
    return String(decoding: data, as: UTF8.self)
  }
}

@available(iOS 26.0, *)
struct MemoDoneIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Mark done"
  @Parameter(title: "Reminder") var reminderId: String

  init() {}
  init(reminderId: String) { self.reminderId = reminderId }

  func perform() async throws -> some IntentResult {
    MemoAlarms.cancel(reminderId: reminderId, oneOffOnly: true)
    MemoAlarms.enqueue(reminderId, "done")
    return .result()
  }
}

@available(iOS 26.0, *)
struct MemoSnoozeIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Snooze 10 minutes"
  @Parameter(title: "Reminder") var reminderId: String
  @Parameter(title: "Title") var title: String
  @Parameter(title: "Sound") var sound: String
  @Parameter(title: "Snooze alarm") var snoozeId: Int

  init() {}
  init(reminderId: String, title: String, sound: String, snoozeId: Int) {
    self.reminderId = reminderId
    self.title = title
    self.sound = sound
    self.snoozeId = snoozeId
  }

  func perform() async throws -> some IntentResult {
    MemoAlarms.cancel(reminderId: reminderId, oneOffOnly: true)
    MemoAlarms.enqueue(reminderId, "snooze")
    // Ring again in 10 minutes even if the app is never opened; Dart replaces
    // this with the full snooze plan (and its nags) on next open.
    try await MemoAlarms.add(MemoFire(
      id: snoozeId,
      at: (Date().timeIntervalSince1970 + 600) * 1000,
      repeat: "none", kind: "snooze", reminderId: reminderId, title: title,
      sound: sound.isEmpty ? nil : sound, snoozeId: snoozeId))
    return .result()
  }
}
