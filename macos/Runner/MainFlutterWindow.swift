import Cocoa
import FlutterMacOS

class SecureFilePickerHandler: NSObject {
    private static let channelName = "musa/secure_file_picker"
    private var channel: FlutterMethodChannel?
    private var pendingResult: FlutterResult?
    private var openPanel: NSOpenPanel?
    private var savePanel: NSSavePanel?

    func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(
            name: Self.channelName,
            binaryMessenger: registrar.messenger)
        channel?.setMethodCallHandler { [weak self] call, result in
            print("[SECURE_PICKER] received method: \(call.method)")
            switch call.method {
            case "pickMusaFile":
                self?.showOpenPanel(result: result)
            case "saveMusaFile":
                self?.showSavePanel(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        print("[SECURE_PICKER] channel registered")
    }

    private func showOpenPanel(result: @escaping FlutterResult) {
        pendingResult = result
        openPanel = NSOpenPanel()
        openPanel!.canChooseFiles = true
        openPanel!.canChooseDirectories = false
        openPanel!.allowsMultipleSelection = false
        openPanel!.allowedFileTypes = ["musa"]
        openPanel!.title = "Abrir proyecto MUSA"
        openPanel!.prompt = "Abrir"

        openPanel!.begin { [weak self] response in
            guard let self = self, let panel = self.openPanel else { return }
            if response == .OK, let url = panel.url {
                let accessGranted = url.startAccessingSecurityScopedResource()
                print("[OPEN_PROJECT] [NATIVE] startAccessingSecurityScopedResource: \(accessGranted)")
                print("[OPEN_PROJECT] [NATIVE] URL path: \(url.path)")
                do {
                    let fileData = try Data(contentsOf: url, options: .mappedIfSafe)
                    print("[OPEN_PROJECT] [NATIVE] Read \(fileData.count) bytes")
                    url.stopAccessingSecurityScopedResource()
                    self.pendingResult?(FlutterStandardTypedData(bytes: fileData))
                } catch {
                    print("[OPEN_PROJECT] [NATIVE] File read error: \(error)")
                    url.stopAccessingSecurityScopedResource()
                    self.pendingResult?(FlutterError(
                        code: "FILE_READ_ERROR",
                        message: "Cannot read file: \(error.localizedDescription)",
                        details: error.localizedDescription))
                }
            } else {
                self.pendingResult?(nil)
            }
            self.pendingResult = nil
            self.openPanel = nil
        }
    }

    private func showSavePanel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let fileName = arguments["fileName"] as? String,
              let typedData = arguments["bytes"] as? FlutterStandardTypedData else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing fileName or bytes for saveMusaFile",
                details: nil))
            return
        }

        pendingResult = result
        savePanel = NSSavePanel()
        savePanel!.allowedFileTypes = ["musa"]
        savePanel!.canCreateDirectories = true
        savePanel!.nameFieldStringValue = fileName
        savePanel!.title = "Guardar proyecto MUSA"
        savePanel!.prompt = "Guardar"

        savePanel!.begin { [weak self] response in
            guard let self = self, let panel = self.savePanel else { return }
            if response == .OK, let url = panel.url {
                let accessGranted = url.startAccessingSecurityScopedResource()
                print("[SAVE_PROJECT] [NATIVE] startAccessingSecurityScopedResource: \(accessGranted)")
                print("[SAVE_PROJECT] [NATIVE] URL path: \(url.path)")
                do {
                    try typedData.data.write(to: url, options: .atomic)
                    print("[SAVE_PROJECT] [NATIVE] Wrote \(typedData.data.count) bytes")
                    url.stopAccessingSecurityScopedResource()
                    self.pendingResult?(url.path)
                } catch {
                    print("[SAVE_PROJECT] [NATIVE] File write error: \(error)")
                    url.stopAccessingSecurityScopedResource()
                    self.pendingResult?(FlutterError(
                        code: "FILE_WRITE_ERROR",
                        message: "Cannot write file: \(error.localizedDescription)",
                        details: error.localizedDescription))
                }
            } else {
                self.pendingResult?(nil)
            }
            self.pendingResult = nil
            self.savePanel = nil
        }
    }
}

/// Method channel para gestionar security-scoped bookmarks de la bandeja de
/// capturas en macOS.
///
/// API:
/// - `pickFolder` → `{ "bookmark": <bytes>, "path": <string> }` o `null` si
///   el usuario cancela.
/// - `resolveBookmark(bookmark: <bytes>)` → `{ "path": <string>, "stale": <bool> }`
///   o lanza `FlutterError` si no se puede resolver.
final class InboxBookmarkChannel: NSObject {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "musa/inbox_bookmark",
      binaryMessenger: messenger
    )
    super.init()
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickFolder":
      pickFolder(result: result)
    case "resolveBookmark":
      resolveBookmark(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pickFolder(result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.message = "Elige la carpeta donde MUSA guardará y leerá tus capturas"
    panel.prompt = "Elegir carpeta"

    panel.begin { response in
      guard response == .OK, let url = panel.url else {
        result(nil)
        return
      }
      do {
        let bookmark = try url.bookmarkData(
          options: [.withSecurityScope],
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
        result([
          "bookmark": FlutterStandardTypedData(bytes: bookmark),
          "path": url.path,
        ])
      } catch {
        result(FlutterError(
          code: "BOOKMARK_FAILED",
          message: "No se pudo crear bookmark: \(error.localizedDescription)",
          details: nil
        ))
      }
    }
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
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      )
      // Iniciamos acceso. Lo dejamos abierto durante la sesión.
      _ = url.startAccessingSecurityScopedResource()
      result([
        "path": url.path,
        "stale": stale,
      ])
    } catch {
      result(FlutterError(
        code: "BOOKMARK_INVALID",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }
}

class MainFlutterWindow: NSWindow {
  private let secureFilePicker = SecureFilePickerHandler()
  private var inboxBookmarkChannel: InboxBookmarkChannel?
  private let initialSize = NSSize(width: 1280, height: 820)
  private let minimumSize = NSSize(width: 1100, height: 720)
  private let trafficLightLeftInset: CGFloat = 14
  private let trafficLightTopInset: CGFloat = 20

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.setContentSize(initialSize)
    self.minSize = minimumSize
    self.center()
    self.setFrameAutosaveName("MUSA.MainWindow")
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = true

    if #available(macOS 11.0, *) {
      self.toolbarStyle = .unifiedCompact
      self.titlebarSeparatorStyle = .none
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    secureFilePicker.register(with: flutterViewController.engine.registrar(forPlugin: "SecureFilePicker"))

    inboxBookmarkChannel = InboxBookmarkChannel(
      messenger: flutterViewController.engine.binaryMessenger
    )

    super.awakeFromNib()
    // positionTrafficLights()
  }

  override func layoutIfNeeded() {
    super.layoutIfNeeded()
    // positionTrafficLights()
  }

  private func positionTrafficLights() {
    guard let closeButton = standardWindowButton(.closeButton),
          let miniaturizeButton = standardWindowButton(.miniaturizeButton),
          let zoomButton = standardWindowButton(.zoomButton) else {
      return
    }

    let buttons = [closeButton, miniaturizeButton, zoomButton]
    let spacing = miniaturizeButton.frame.minX - closeButton.frame.maxX
    let y = frame.height - trafficLightTopInset - closeButton.frame.height

    var x = trafficLightLeftInset
    for button in buttons {
      button.setFrameOrigin(NSPoint(x: x, y: y))
      x += button.frame.width + spacing
    }
  }
}
