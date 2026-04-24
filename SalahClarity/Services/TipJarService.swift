//
//  TipJarService.swift
//  Salah Clarity
//
//  StoreKit 2 tip jar. Supports non-consumable tips so the user can "support
//  the dev" multiple times (treated as consumables conceptually, but the
//  product type is `.consumable` in App Store Connect — cheapest to manage).
//
//  To enable:
//    1. In App Store Connect, add two consumable in-app purchases:
//         com.yourname.salahclarity.tip.small   ($0.99)
//         com.yourname.salahclarity.tip.medium  ($2.99)
//    2. Create a `Products.storekit` StoreKit configuration file in Xcode
//       for local testing, and add both product IDs.
//    3. Update `productIDs` below to match.
//

import Foundation
import StoreKit
import Observation

@Observable
final class TipJarService {

    static let shared = TipJarService()

    // TODO: Replace these with your actual product IDs from App Store Connect.
    private let productIDs: Set<String> = [
        "com.yourname.salahclarity.tip.small",
        "com.yourname.salahclarity.tip.medium"
    ]

    private(set) var products: [Product] = []
    private(set) var isLoading: Bool = false
    private(set) var lastError: String?

    private init() {
        Task { await loadProducts() }
        observeTransactions()
    }

    // MARK: - Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: productIDs)
            self.products = loaded.sorted { $0.price < $1.price }
        } catch {
            lastError = error.localizedDescription
            CrashReportingService.shared.record(error: error)
        }
    }

    // MARK: - Purchase

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    AnalyticsService.shared.log(event: "tip_purchased",
                                                params: ["product_id": product.id])
                    return true
                }
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            CrashReportingService.shared.record(error: error)
            return false
        }
    }

    // MARK: - Transaction listener

    private func observeTransactions() {
        Task.detached {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
            }
        }
    }
}
