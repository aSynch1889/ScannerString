import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: StoreError?

    private let productIds = ["com.scannerstring.subscription.unlimited01"]
    private var updateListenerTask: Task<Void, Error>?
    private var isInitialized = false
    
    private init() {
        Task {
            await start()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func start() async {
        // 确保只启动一次
        guard !isInitialized else { return }
        isInitialized = true

        isLoading = true
        error = nil

        // 开始监听交易更新
        updateListenerTask = Task.detached { [weak self] in
            guard let self = self else { return }

            // 监听所有交易更新
            for await result in StoreKit.Transaction.updates {
                await self.handleTransactionResult(result)
            }
        }

        // 加载产品和更新购买状态
        await loadProducts()
        await updatePurchasedProducts()

        isLoading = false
    }
    
    private func handleTransactionResult(_ result: VerificationResult<StoreKit.Transaction>) async {
        switch result {
        case .verified(let transaction):
            await updatePurchasedProducts()
            await transaction.finish()
        case .unverified:
            await MainActor.run {
                self.error = .failedVerification
            }
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
            error = nil
        } catch {
            self.error = .networkError(error)
        }
    }
    
    func purchase(_ product: Product) async throws {
        error = nil

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await updatePurchasedProducts()
                await transaction.finish()
            case .unverified:
                await MainActor.run {
                    self.error = .failedVerification
                }
                throw StoreError.failedVerification
            }
        case .userCancelled:
            await MainActor.run {
                self.error = .userCancelled
            }
            throw StoreError.userCancelled
        case .pending:
            await MainActor.run {
                self.error = .pending
            }
            throw StoreError.pending
        @unknown default:
            await MainActor.run {
                self.error = .unknown
            }
            throw StoreError.unknown
        }
    }
    
    func updatePurchasedProducts() async {
        var newPurchasedSubscriptions: [Product] = []

        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if let subscription = products.first(where: { $0.id == transaction.productID }) {
                    newPurchasedSubscriptions.append(subscription)
                }
            case .unverified:
                continue
            }
        }

        await MainActor.run {
            self.purchasedSubscriptions = newPurchasedSubscriptions
        }
    }
    
    var hasUnlimitedSubscription: Bool {
        !purchasedSubscriptions.isEmpty
    }
    
    // 用于测试的方法
    #if DEBUG
    func resetPurchases() async {
        await MainActor.run {
            self.purchasedSubscriptions.removeAll()
        }
        // 注意：真正的重置需要通过App Store Connect测试环境
        // 这里只是临时清除本地状态用于调试
    }
    #endif
}

enum StoreError: Error, LocalizedError {
    case failedVerification
    case userCancelled
    case pending
    case unknown
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed".localized
        case .userCancelled:
            return "Purchase cancelled".localized
        case .pending:
            return "Purchase is pending".localized
        case .unknown:
            return "Unknown error occurred".localized
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)".localized
        }
    }
} 
