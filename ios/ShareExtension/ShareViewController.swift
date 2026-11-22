import UIKit
import UniformTypeIdentifiers

/// Share Extension: appends the shared text to the App Group queue that
/// Runner's AlarmPlugin serves to Dart. No Flutter, no network, no logging.
final class ShareViewController: UIViewController {
  private var done = false

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !done else { return }
    done = true
    let type = UTType.plainText.identifier
    let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
    let provider = items.flatMap { $0.attachments ?? [] }
      .first { $0.hasItemConformingToTypeIdentifier(type) }
    guard let provider else { return finish("share_nothing") }
    provider.loadItem(forTypeIdentifier: type) { item, _ in
      let raw = (item as? String) ?? (item as? URL)?.absoluteString
        ?? (item as? Data).flatMap { String(data: $0, encoding: .utf8) }
        ?? (item as? NSAttributedString)?.string ?? ""
      let text = String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(4000))
      DispatchQueue.main.async {
        guard !text.isEmpty else { return self.finish("share_nothing") }
        // ponytail: read-modify-write on the queue can race with the app's ackShare; tiny window, accepted. Upgrade: NSFileCoordinator.
        let defaults = UserDefaults(suiteName: "group.in.appamania.memo")
        var shares = defaults?.array(forKey: "shares") as? [[String: Any]] ?? []
        shares.append([
          "id": UUID().uuidString, "text": text,
          "at": Int(Date().timeIntervalSince1970 * 1000),
        ])
        defaults?.set(Array(shares.suffix(20)), forKey: "shares")
        self.finish("share_added")
      }
    }
  }

  private func finish(_ key: String) {
    let alert = UIAlertController(title: nil, message: NSLocalizedString(key, comment: ""), preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
      self.extensionContext?.completeRequest(returningItems: nil)
    })
    present(alert, animated: true)
  }
}
