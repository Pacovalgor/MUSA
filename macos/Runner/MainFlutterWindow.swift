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

class MainFlutterWindow: NSWindow {
  private let secureFilePicker = SecureFilePickerHandler()
  private let initialSize = NSSize(width: 1280, height: 820)
  private let minimumSize = NSSize(width: 1100, height: 720)
  private let trafficLightLeftInset: CGFloat = 14
  private let trafficLightTopInset: CGFloat = 16

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

    super.awakeFromNib()
    positionTrafficLights()
  }

  override func layoutIfNeeded() {
    super.layoutIfNeeded()
    positionTrafficLights()
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
