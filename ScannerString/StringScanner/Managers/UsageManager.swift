import Foundation

@MainActor
class UsageManager: ObservableObject {
    static let shared = UsageManager()
    
    @Published private(set) var lastScanDate: Date?
    @Published private(set) var canScanToday: Bool = true
    
    private let userDefaults = UserDefaults.standard
    private let lastScanDateKey = "lastScanDate"
    
    private init() {
        loadLastScanDate()
        checkDailyLimit()
    }
    
    private func loadLastScanDate() {
        if let date = userDefaults.object(forKey: lastScanDateKey) as? Date {
            lastScanDate = date
        }
    }
    
    private func checkDailyLimit() {
        guard let lastScan = lastScanDate else {
            canScanToday = true
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        canScanToday = !calendar.isDate(lastScan, inSameDayAs: today)
    }
    
    func recordScan() {
        lastScanDate = Date()
        userDefaults.set(lastScanDate, forKey: lastScanDateKey)
        canScanToday = false
    }
    
    func canPerformScan() -> Bool {
        return StoreManager.shared.hasUnlimitedSubscription || canScanToday
    }
    
    func remainingScansToday() -> Int {
        if StoreManager.shared.hasUnlimitedSubscription {
            return Int.max
        }
        return canScanToday ? 1 : 0
    }
} 
