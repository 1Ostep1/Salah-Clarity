//
//  CrashReportingService.swift
//  Salah Clarity
//
//  Firebase Crashlytics wrapper. No-op until SDK is added.
//
//  To enable:
//    1. Add `FirebaseCrashlytics` from the firebase-ios-sdk SPM package.
//    2. Add the Crashlytics run script build phase (dSYM upload).
//    3. Uncomment the import + calls below.
//

import Foundation
import FirebaseCrashlytics

final class CrashReportingService {

    static let shared = CrashReportingService()
    private init() {}

    /// Record a non-fatal error (e.g., location failure, calculation edge case).
    func record(error: Error) {
        #if DEBUG
        print("[Crash] \(error.localizedDescription)")
        #endif
        Crashlytics.crashlytics().record(error: error)
    }

    /// Leave a breadcrumb to help debug future crashes.
    func log(_ message: String) {
        #if DEBUG
        print("[Crash.log] \(message)")
        #endif
        Crashlytics.crashlytics().log(message)
    }
}
