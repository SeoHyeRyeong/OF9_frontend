import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var methodChannel: FlutterMethodChannel?

  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ✅ MethodChannel 설정
    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(
        name: "com.of9.dodada/deeplink",
        binaryMessenger: controller.binaryMessenger
    )

    // ✅ FCM 설정 추가!
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ APNs 토큰 등록 (추가!)
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    print("✅ APNs 토큰 등록 완료")
  }

  // ✅ Universal Links 처리
  override func application(
      _ application: UIApplication,
      continue userActivity: NSUserActivity,
      restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {

    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {

      print("✅ [Native] Universal Link 수신: \(url.absoluteString)")

      // ✅ 즉시 window 활성화 (iOS에 "처리 중" 신호)
      window?.makeKeyAndVisible()

      // ✅ Flutter에 URL 전달
      methodChannel?.invokeMethod("handleDeepLink", arguments: url.absoluteString)

      print("✅ [Native] iOS에 처리 완료 신호 전송")
      return true  // 중요!
    }

    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
