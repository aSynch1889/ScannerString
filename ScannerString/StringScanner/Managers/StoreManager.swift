import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    
    private let productIds = ["com.scannerstring.subscription.unlimited"]
    
    private init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await updatePurchasedProducts()
                await transaction.finish()
            case .unverified:
                throw StoreError.failedVerification
            }
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            throw StoreError.pending
        @unknown default:
            throw StoreError.unknown
        }
    }
    
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if let subscription = products.first(where: { $0.id == transaction.productID }) {
                    purchasedSubscriptions.append(subscription)
                }
            case .unverified:
                continue
            }
        }
    }
    
    var hasUnlimitedSubscription: Bool {
        !purchasedSubscriptions.isEmpty
    }
}

enum StoreError: Error {
    case failedVerification
    case userCancelled
    case pending
    case unknown
} 