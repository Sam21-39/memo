import Flutter
import UIKit

/// `memo/alarm` on iOS: puts a voice clip where a notification can ring it,
/// and reports Reduce Transparency so chrome can go solid. Android's half of
/// the channel lives in MainActivity.kt.
final class AlarmPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "memo/alarm", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(AlarmPlugin(), channel: channel)
  }

  /// Library/Sounds is where UNNotificationSound(named:) looks.
  private var soundsDir: URL {
    FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Sounds", isDirectory: true)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "installSound":
      guard let path = args?["path"] as? String, let id = args?["id"] as? String else {
        return result(FlutterError(code: "args", message: "path and id required", details: nil))
      }
      do {
        try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
        let target = soundsDir.appendingPathComponent("\(id).wav")
        try? FileManager.default.removeItem(at: target)
        try FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: target)
        result(nil)
      } catch {
        result(FlutterError(code: "io", message: error.localizedDescription, details: nil))
      }
    case "removeSound":
      if let id = args?["id"] as? String {
        try? FileManager.default.removeItem(at: soundsDir.appendingPathComponent("\(id).wav"))
      }
      result(nil)
    case "reduceTransparency":
      result(UIAccessibility.isReduceTransparencyEnabled)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
