import Flutter
import LocalAuthentication
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let screenLock = ScreenLockBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ScreenLock") {
      screenLock.attach(to: registrar.messenger())
    }
  }
}

/// แยก "จอล็อกเอง" ออกจาก "สลับไปแอปอื่น" (§2.4)
///
/// iOS ไม่มี API ที่บอกตรงๆ ว่าจอถูกล็อก แต่ตอนล็อกเครื่องที่ตั้งรหัสผ่านไว้
/// ระบบจะปิดการเข้าถึงข้อมูลที่ถูกป้องกันแล้วยิง
/// `protectedDataWillBecomeUnavailable` ซึ่ง **ไม่ยิงตอนสลับไปแอปอื่น**
/// ทั้งสองตัวเป็น public API ไม่เสี่ยงกับการรีวิวของ App Store
///
/// เก็บเป็น **ช่วงเวลา** ไม่ใช่สถานะปัจจุบัน เพราะฝั่ง Dart ตัดสินตอนกลับเข้าแอป
/// ไม่ใช่ตอนออก — iOS ไม่รับประกันลำดับระหว่างสัญญาณนี้กับ lifecycle
///
/// ข้อจำกัด: เครื่องที่ไม่ได้ตั้งรหัสผ่าน data protection ไม่ทำงาน
/// สัญญาณนี้จะไม่ยิงเลย ฝั่ง Dart จึงถาม `hasPasscode` ก่อนเชื่อผลลัพธ์
final class ScreenLockBridge: NSObject {
  private var lockStartMs: Int64?
  private var lockEndMs: Int64?
  private var channel: FlutterMethodChannel?

  func attach(to messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "app.lapse/screen_lock", binaryMessenger: messenger)
    channel?.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(FlutterMethodNotImplemented) }
      switch call.method {
      case "hasPasscode":
        result(LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil))
      case "lastLockWindow":
        var window: [String: Any] = [:]
        if let start = self.lockStartMs { window["start"] = start }
        if let end = self.lockEndMs { window["end"] = end }
        result(window)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(willLock),
      name: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil)
    center.addObserver(
      self, selector: #selector(didUnlock),
      name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)
  }

  private func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }

  @objc private func willLock() {
    lockStartMs = nowMs()
    lockEndMs = nil
  }

  @objc private func didUnlock() {
    lockEndMs = nowMs()
  }
}
