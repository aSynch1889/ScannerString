import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // 顶部标题栏
            HStack {
                Text("Subscription".localized)
                    .font(.headline)
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // 主要内容
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部图标和标题
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        Text("Unlimited Scan Subscription".localized)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Get unlimited scans every day".localized)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // 价格卡片
                    if let product = storeManager.products.first {
                        VStack(spacing: 8) {
                            Text(product.displayPrice)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("One-time purchase".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    // 错误信息
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // 购买按钮
                    Button(action: {
                        Task {
                            await purchaseSubscription()
                        }
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Purchase".localized)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(storeManager.hasUnlimitedSubscription ? Color.accentColor : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing || storeManager.hasUnlimitedSubscription)
                    .padding(.horizontal)
                    
                    // 已购买状态
                    if storeManager.hasUnlimitedSubscription {
                        Text("You have unlimited scans!".localized)
                            .foregroundColor(.accentColor)
                            .font(.headline)
                    }
                    
                    // 测试重置按钮
                    #if DEBUG
                    if storeManager.hasUnlimitedSubscription {
                        Button("Reset Purchase (Test Only)".localized) {
                            Task {
                                await storeManager.resetPurchases()
                            }
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    #endif
                }
                .padding()
            }
        }
        .frame(width: 400, height: 500)
    }
    
    private func purchaseSubscription() async {
        guard let product = storeManager.products.first else { return }
        
        isPurchasing = true
        errorMessage = nil
        
        do {
            try await storeManager.purchase(product)
        } catch StoreError.userCancelled {
            errorMessage = "Purchase cancelled".localized
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)".localized
        }
        
        isPurchasing = false
    }
}

#Preview {
    SubscriptionView()
} 
