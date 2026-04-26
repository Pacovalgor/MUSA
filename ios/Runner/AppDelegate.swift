import Flutter
import UIKit
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Method channel para gestionar security-scoped bookmarks de la bandeja de
/// capturas en iOS.
///
/// API:
/// - `pickFolder` → presenta `UIDocumentPickerViewController` (modo open de
///   carpeta) y, al elegir, devuelve `{ "bookmark": <bytes>, "path": <string> }`.
///   `null` si el usuario cancela.
/// - `resolveBookmark(bookmark: <bytes>)` → `{ "path": <string>, "stale": <bool> }`
///   o lanza `FlutterError` si no se puede resolver.
final class InboxBookmarkChannel: NSObject, UIDocumentPickerDelegate {
  private let channel: FlutterMethodChannel
  private weak var rootViewController: UIViewController?
  private var pendingResult: FlutterResult?

  init(messenger: FlutterBinaryMessenger, rootViewController: UIViewController?) {
    self.channel = FlutterMethodChannel(
      name: "musa/inbox_bookmark",
      binaryMessenger: messenger
    )
    self.rootViewController = rootViewController
    super.init()
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickFolder": pickFolder(result: result)
    case "resolveBookmark": resolveBookmark(call: call, result: result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func pickFolder(result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "BUSY", message: "Picker already open", details: nil))
      return
    }
    pendingResult = result

    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    } else {
      picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
    }
    picker.allowsMultipleSelection = false
    picker.delegate = self
    rootViewController?.present(picker, animated: true)
  }

  private func resolveBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let blob = args["bookmark"] as? FlutterStandardTypedData
    else {
      result(FlutterError(code: "BAD_ARGS", message: "missing bookmark", details: nil))
      return
    }
    var stale = false
    do {
      let url = try URL(
        resolvingBookmarkData: blob.data,
        options: [],
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      )
      _ = url.startAccessingSecurityScopedResource()
      result(["path": url.path, "stale": stale])
    } catch {
      result(FlutterError(code: "BOOKMARK_INVALID", message: error.localizedDescription, details: nil))
    }
  }

  // MARK: - UIDocumentPickerDelegate

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first, let result = pendingResult else { return }
    pendingResult = nil
    do {
      _ = url.startAccessingSecurityScopedResource()
      let bookmark = try url.bookmarkData()
      result([
        "bookmark": FlutterStandardTypedData(bytes: bookmark),
        "path": url.path,
      ])
    } catch {
      result(FlutterError(code: "BOOKMARK_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingResult?(nil)
    pendingResult = nil
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var inboxBookmarkChannel: InboxBookmarkChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      inboxBookmarkChannel = InboxBookmarkChannel(
        messenger: controller.binaryMessenger,
        rootViewController: controller
      )
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
