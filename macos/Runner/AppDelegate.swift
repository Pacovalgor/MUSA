import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var appMenuChannel: FlutterMethodChannel? {
    guard let flutterViewController = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return nil
    }
    return FlutterMethodChannel(
      name: "musa/app_menu",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  @IBAction func showSettings(_ sender: Any?) {
    appMenuChannel?.invokeMethod("showSettings", arguments: nil)
  }

  @IBAction func showAbout(_ sender: Any?) {
    let infoDictionary = Bundle.main.infoDictionary
    let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"

    NSApp.orderFrontStandardAboutPanel(options: [
      .applicationName: "Musa",
      .applicationVersion: "Version \(version) (\(build))",
      .credits: NSAttributedString(
        string: "MUSA\nPor Francisco Valiente Gordo\n\nEscritura asistida con una interfaz editorial pensada para macOS.",
        attributes: [
          .font: NSFont.systemFont(ofSize: 12),
          .foregroundColor: NSColor.secondaryLabelColor,
        ]),
    ])
    NSApp.activate(ignoringOtherApps: true)
  }
}
