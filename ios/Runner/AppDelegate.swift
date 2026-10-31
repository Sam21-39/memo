import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications surface alerts while the app is in the
    // foreground and deliver Done/Snooze action taps back to Dart.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    // Done and Snooze run in a background isolate; it needs the same plugins
    // (sqflite, shared_preferences, the notification plugin itself).
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AlarmPlugin") {
      AlarmPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SttPlugin") {
      SttPlugin.register(with: registrar)
    }
  }
}
