import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    
    private let productIds = ["com.scannerstring.subscription.unlimited"]
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // 初始化时不自动启动监听，等待显式调用 start()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func start() {
        // 确保只启动一次
        guard updateListenerTask == nil else { return }
        
        // 开始监听交易更新
        updateListenerTask = Task.detached { [weak self] in
            guard let self = self else { return }
            
            // 监听所有交易更新
            for await result in StoreKit.Transaction.updates {
                await self.handleTransactionResult(result)
            }
        }
        
        // 加载产品和更新购买状态
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    private func handleTransactionResult(_ result: VerificationResult<StoreKit.Transaction>) async {
        switch result {
        case .verified(let transaction):
            // 确保在主线程上更新 UI
            await MainActor.run {
                Task {
                    await self.updatePurchasedProducts()
                }
            }
            await transaction.finish()
        case .unverified:
            print("Transaction verification failed")
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
        purchasedSubscriptions.removeAll()
        
        for await result in StoreKit.Transaction.currentEntitlements {
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
    
    // 用于测试的方法
    #if DEBUG
    func resetPurchases() async {
        for productId in productIds {
            if let result = await StoreKit.Transaction.latest(for: productId) {
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                case .unverified:
                    print("Transaction verification failed for product: \(productId)")
                }
            }
        }
        purchasedSubscriptions.removeAll()
    }
    #endif
}

enum StoreError: Error {
    case failedVerification
    case userCancelled
    case pending
    case unknown
} 
