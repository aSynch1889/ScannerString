import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager.shared
    @State private var isPurchasing = false
    @State private var showingSuccessMessage = false
    
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
                    VStack(spacing: 8) {
                        if storeManager.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                        } else if let product = storeManager.products.first {
                            Text(product.displayPrice)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)

                            Text("One-time purchase".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Unable to load pricing".localized)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(16)
                    
                    // 状态消息
                    if let error = storeManager.error {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    if showingSuccessMessage {
                        Text("Purchase successful!".localized)
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // 购买按钮
                    if storeManager.hasUnlimitedSubscription {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Already Purchased".localized)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
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
                            .background(storeManager.products.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .disabled(isPurchasing || storeManager.products.isEmpty || storeManager.isLoading)
                        .padding(.horizontal)
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
        .frame(minWidth: 350, maxWidth: 450, minHeight: 400, maxHeight: 600)
    }
    
    private func purchaseSubscription() async {
        guard let product = storeManager.products.first else { return }

        isPurchasing = true
        showingSuccessMessage = false

        do {
            try await storeManager.purchase(product)
            showingSuccessMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingSuccessMessage = false
            }
        } catch {
            // 错误已经在 StoreManager 中设置
        }

        isPurchasing = false
    }
}

#Preview {
    SubscriptionView()
} 
