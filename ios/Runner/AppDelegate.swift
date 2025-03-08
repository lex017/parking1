import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Make sure to replace the API key with your actual Google Maps API key
    GMSServices.provideAPIKey("AIzaSyCmE-nJ96Uo5rmgor9OqItPcxJNZdVQMBo")

    // Registers plugins for your app
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
