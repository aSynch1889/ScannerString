import Foundation

@MainActor
class UsageManager: ObservableObject {
    static let shared = UsageManager()

    // 注释掉使用次数限制相关属性 - 改为付费下载模式
    // @Published private(set) var lastScanDate: Date?
    // @Published private(set) var canScanToday: Bool = true

    // private let userDefaults = UserDefaults.standard
    // private let lastScanDateKey = "lastScanDate"

    private init() {
        // 注释掉限制检查 - 付费下载后无限制使用
        // loadLastScanDate()
        // checkDailyLimit()
    }
    
    // private func loadLastScanDate() {
    //     if let date = userDefaults.object(forKey: lastScanDateKey) as? Date {
    //         lastScanDate = date
    //     }
    // }
    
    // private func checkDailyLimit() {
    //     guard let lastScan = lastScanDate else {
    //         canScanToday = true
    //         return
    //     }
    //
    //     let calendar = Calendar.current
    //     let today = Date()
    //
    //     canScanToday = !calendar.isDate(lastScan, inSameDayAs: today)
    // }
    
    // 注释掉记录使用次数的方法 - 付费下载模式无限制
    func recordScan() {
        // 付费下载模式下无需记录使用次数
        // lastScanDate = Date()
        // userDefaults.set(lastScanDate, forKey: lastScanDateKey)
        // canScanToday = false
    }
    
    // 付费下载模式：始终允许扫描
    func canPerformScan() -> Bool {
        return true  // 付费下载后无限制使用
    }
    
    // 付费下载模式：无限扫描次数
    func remainingScansToday() -> Int {
        return Int.max  // 付费下载后无限使用
    }
} 
