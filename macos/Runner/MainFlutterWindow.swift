import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
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
