import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAppIconChannel(engineBridge)
  }

  /// Themed app icon. Each theme's poster icon is an alternate icon set
  /// ("AppIcon-<id-with-hyphens>", listed in ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES);
  /// the default theme uses the primary "AppIcon" set (name == nil).
  private func registerAppIconChannel(_ engineBridge: FlutterImplicitEngineBridge) {
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DripAppIcon") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "drip/app_icon",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "setIcon" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
        let id = args["id"] as? String,
        let isDefault = args["isDefault"] as? Bool
      else {
        result(FlutterError(code: "bad_args", message: "expected id + isDefault", details: nil))
        return
      }
      guard UIApplication.shared.supportsAlternateIcons else {
        result(nil)
        return
      }
      let name: String? = isDefault ? nil : "AppIcon-" + id.replacingOccurrences(of: "_", with: "-")
      // Already showing it: don't trigger iOS's "icon changed" alert again.
      if UIApplication.shared.alternateIconName == name {
        result(nil)
        return
      }
      UIApplication.shared.setAlternateIconName(name) { error in
        if let error = error {
          result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }
  }
}
