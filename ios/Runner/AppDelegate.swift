import Flutter
import UIKit
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  private var locationManager: CLLocationManager?
  private var methodChannel: FlutterMethodChannel?
  private var pendingLocation: CLLocation?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up MethodChannel for communication with Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      methodChannel = FlutterMethodChannel(
        name: "com.coordinate/significant_location",
        binaryMessenger: controller.binaryMessenger
      )
      
      // Handle method calls from Flutter
      methodChannel?.setMethodCallHandler { [weak self] (call, result) in
        switch call.method {
        case "startMonitoring":
          self?.startSignificantLocationMonitoring()
          result(nil)
        case "stopMonitoring":
          self?.stopSignificantLocationMonitoring()
          result(nil)
        case "isMonitoring":
          result(self?.locationManager != nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    // Check if app was launched due to a location event
    if launchOptions?[.location] != nil {
      NSLog("AppDelegate: App launched due to location event")
      startSignificantLocationMonitoring()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Significant Location Change Monitoring
  
  private func startSignificantLocationMonitoring() {
    guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
      NSLog("AppDelegate: Significant location change monitoring not available")
      return
    }
    
    if locationManager == nil {
      locationManager = CLLocationManager()
      locationManager?.delegate = self
      locationManager?.allowsBackgroundLocationUpdates = true
      locationManager?.pausesLocationUpdatesAutomatically = false
    }
    
    // Check authorization status
    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = locationManager?.authorizationStatus ?? .notDetermined
    } else {
      status = CLLocationManager.authorizationStatus()
    }
    
    switch status {
    case .authorizedAlways:
      NSLog("AppDelegate: Starting significant location change monitoring")
      locationManager?.startMonitoringSignificantLocationChanges()
    case .authorizedWhenInUse:
      NSLog("AppDelegate: Only 'When In Use' permission - requesting 'Always'")
      locationManager?.requestAlwaysAuthorization()
    case .notDetermined:
      NSLog("AppDelegate: Permission not determined - requesting")
      locationManager?.requestAlwaysAuthorization()
    default:
      NSLog("AppDelegate: Location permission denied")
    }
  }
  
  private func stopSignificantLocationMonitoring() {
    NSLog("AppDelegate: Stopping significant location change monitoring")
    locationManager?.stopMonitoringSignificantLocationChanges()
    locationManager = nil
  }
  
  // MARK: - CLLocationManagerDelegate
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    
    NSLog("AppDelegate: Received significant location change: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    
    // Send location to Flutter
    let locationData: [String: Any] = [
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "accuracy": location.horizontalAccuracy,
      "timestamp": location.timestamp.timeIntervalSince1970 * 1000
    ]
    
    // If Flutter engine is ready, send immediately
    // Otherwise, store for later
    if methodChannel != nil {
      methodChannel?.invokeMethod("onSignificantLocationChange", arguments: locationData)
    } else {
      pendingLocation = location
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    NSLog("AppDelegate: Location error: \(error.localizedDescription)")
  }
  
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = manager.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }
    NSLog("AppDelegate: Authorization status changed to: \(status.rawValue)")
    
    if status == .authorizedAlways {
      NSLog("AppDelegate: 'Always' permission granted - starting monitoring")
      locationManager?.startMonitoringSignificantLocationChanges()
    }
  }
  
  // Called when Flutter engine is ready (for pending locations)
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    
    // Send any pending location that was received while app was launching
    if let location = pendingLocation, methodChannel != nil {
      let locationData: [String: Any] = [
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
        "accuracy": location.horizontalAccuracy,
        "timestamp": location.timestamp.timeIntervalSince1970 * 1000
      ]
      methodChannel?.invokeMethod("onSignificantLocationChange", arguments: locationData)
      pendingLocation = nil
    }
  }
}
