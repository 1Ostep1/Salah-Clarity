//
//  AnalyticsService.swift
//  Salah Clarity
//
//  Thin wrapper around Firebase Analytics. Runs as a no-op until the SDK is added.
//
//  To enable:
//    1. Add firebase-ios-sdk via Swift Package Manager.
//    2. Select the `FirebaseAnalytics` product.
//    3. Drop `GoogleService-Info.plist` into the app target.
//    4. Uncomment `FirebaseApp.configure()` in SalahClarityApp.init.
//    5. Uncomment the `import FirebaseAnalytics` + `Analytics.logEvent(...)` lines below.
//

import Foundation
import FirebaseAnalytics

final class AnalyticsService {

    static let shared = AnalyticsService()
    private init() {}

    func logAppLaunch() {
        log(event: "app_launch", params: [:])
    }

    /// Log a custom event. All params must be String-valued (Firebase requirement).
    func log(event: String, params: [String: String]) {
        #if DEBUG
        print("[Analytics] \(event) \(params)")
        #endif
        Analytics.logEvent(event, parameters: params)
    }

    func setUserProperty(_ value: String?, name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
}
