# ScannerString 项目开发方案

## 🎯 项目现状总结

这是一个功能相对完善的 **macOS 字符串扫描工具**，包含：
- 完整的 SwiftUI 图形界面
- Swift Syntax 解析核心
- 多语言国际化支持
- App Store 内购订阅功能（已注释）
- 多种导出格式支持

## 🚀 优先发展方向

### 1. **核心功能增强**

**字符串过滤和筛选功能**
- **语言过滤器**：根据字符串内容自动检测语言类型，支持过滤特定语言的字符串
  - 中文字符串筛选（包含中日韩字符）
  - 英文字符串筛选（纯ASCII字符）
  - 混合语言字符串识别
- **重复字符串检测和过滤**：
  - 检测项目中的重复字符串
  - 提供去重选项和统计信息
  - 显示重复字符串的使用位置和频次
- **无效字符串过滤**：
  - 过滤空字符串和空白字符串
  - 过滤单字符或过短的字符串
  - 过滤纯数字、纯符号等无意义字符串
  - 可配置的最小字符串长度阈值

**字符串类型检测扩展**
- 支持更多字符串类型：URL、文件路径、颜色值、API endpoints
- 检测硬编码的敏感信息（API keys、密码等）
- 支持 SwiftUI Text 组件和 AttributedString

**代码覆盖率提升**
- 支持 Objective-C++ (.mm) 文件
- 解析 Interface Builder (.xib/.storyboard) 文件中的字符串
- 扫描 Info.plist 和配置文件

### 2. **测试质量改进**

当前项目 **缺少测试文件**，这是最重要的改进点：

```swift
// 建议添加的测试结构
Tests/
├── ScannerStringCoreTests/
│   ├── ProjectScannerTests.swift
│   ├── StringVisitorTests.swift
│   ├── StringFilterTests.swift        // 新增：字符串过滤测试
│   ├── LanguageDetectorTests.swift    // 新增：语言检测测试
│   └── TestFixtures/
└── ScannerStringUITests/
    ├── ContentViewTests.swift
    └── ScannerViewModelTests.swift
```

### 3. **性能和用户体验优化**

**扫描性能**
- 增量扫描（只扫描变更的文件）
- 内存优化（大项目的内存使用）
- 可配置的并发数

**用户界面改进**
- 添加搜索和过滤功能界面
- 字符串分类视图（本地化/硬编码/URL等）
- 支持深色主题优化
- **过滤器控制面板**：
  - 语言类型选择器
  - 重复字符串显示开关
  - 最小长度滑块控制
  - 字符串类型过滤选项

### 4. **集成和扩展能力**

**命令行工具**
```swift
// 添加 CLI 入口点，支持过滤参数
@main
struct ScannerCLI {
    static func main() async throws {
        // 支持命令行过滤选项
        // --language=zh|en|mixed
        // --min-length=3
        // --exclude-duplicates
        // --exclude-empty
    }
}
```

**插件生态**
- Xcode Source Editor Extension
- VS Code 插件支持
- GitHub Action 集成

## 🛠 技术架构改进

### 1. **模块化重构**

将核心扫描逻辑独立为 Package：

```swift
// 建议的包结构
ScannerStringCore/           // 核心扫描逻辑
├── Sources/
│   ├── ScannerCore/        // 主要扫描功能
│   ├── Filters/            // 新增：字符串过滤器模块
│   │   ├── LanguageFilter.swift
│   │   ├── DuplicateFilter.swift
│   │   └── ContentFilter.swift
│   ├── Exporters/          // 导出格式处理
│   └── Utils/              // 工具类
├── Tests/
└── Package.swift

ScannerStringApp/           // macOS 应用
ScannerStringCLI/          // 命令行工具
```

### 2. **过滤器架构设计**

```swift
// 过滤器协议
protocol StringFilter {
    func shouldInclude(_ location: StringLocation) -> Bool
    var name: String { get }
    var description: String { get }
}

// 语言过滤器
struct LanguageFilter: StringFilter {
    enum Language {
        case chinese, english, mixed, numeric, symbolic
    }

    let targetLanguages: Set<Language>

    func shouldInclude(_ location: StringLocation) -> Bool {
        let detectedLanguage = detectLanguage(location.content)
        return targetLanguages.contains(detectedLanguage)
    }
}

// 重复字符串过滤器
struct DuplicateFilter: StringFilter {
    let excludeDuplicates: Bool
    private var seenStrings: Set<String> = []

    mutating func shouldInclude(_ location: StringLocation) -> Bool {
        if excludeDuplicates {
            return seenStrings.insert(location.content).inserted
        }
        return true
    }
}

// 内容过滤器
struct ContentFilter: StringFilter {
    let minLength: Int
    let excludeEmpty: Bool
    let excludeNumericOnly: Bool

    func shouldInclude(_ location: StringLocation) -> Bool {
        let content = location.content.trimmingCharacters(in: .whitespacesAndNewlines)

        if excludeEmpty && content.isEmpty {
            return false
        }

        if content.count < minLength {
            return false
        }

        if excludeNumericOnly && content.allSatisfy(\.isNumber) {
            return false
        }

        return true
    }
}

// 过滤器管理器
class FilterManager {
    private var filters: [StringFilter] = []

    func addFilter(_ filter: StringFilter) {
        filters.append(filter)
    }

    func applyFilters(to results: [StringLocation]) -> [StringLocation] {
        return results.filter { location in
            filters.allSatisfy { $0.shouldInclude(location) }
        }
    }
}
```

### 3. **配置文件支持**

添加 `.scannerstring.yml` 配置：

```yaml
# 扫描配置
scan:
  include_paths: ["Sources/", "Apps/"]
  exclude_paths: ["Tests/", "Pods/"]
  file_types: ["swift", "m", "h", "mm"]

# 过滤器配置
filters:
  language:
    enabled: true
    include: ["chinese", "english"]  # 或 "all"

  duplicates:
    enabled: true
    exclude_duplicates: true

  content:
    enabled: true
    min_length: 3
    exclude_empty: true
    exclude_numeric_only: true

# 导出设置
export:
  default_format: "json"
  include_location: true
  include_filter_info: true
```

### 4. **数据结构扩展**

```swift
// 扩展 StringLocation 以支持更多信息
public struct StringLocation: Codable, Hashable {
    public let file: String
    public let line: Int
    public let column: Int
    public let content: String
    public let isLocalized: Bool

    // 新增字段
    public let detectedLanguage: DetectedLanguage?
    public let contentType: StringContentType
    public let isDuplicate: Bool
    public let duplicateCount: Int?

    public enum DetectedLanguage: String, Codable {
        case chinese, english, mixed, numeric, symbolic, unknown
    }

    public enum StringContentType: String, Codable {
        case normal, url, filePath, apiEndpoint, colorValue, sensitive
    }
}
```

## 🎯 快速上手建议

基于你的 CLAUDE.md 开发指导原则，建议按以下**渐进式**方式开展：

**阶段 1**（1-2 周）：添加完整测试覆盖
- 为现有核心功能添加单元测试
- 建立测试框架和固定测试数据

**阶段 2**（1-2 周）：实现字符串过滤功能
- 实现语言检测和过滤
- 添加重复字符串检测
- 实现内容过滤器（空字符串、最小长度等）

**阶段 3**（1 周）：重构为模块化架构
- 将过滤器逻辑独立为模块
- 重构现有代码以支持过滤器

**阶段 4**（1 周）：用户界面增强
- 添加过滤器控制面板
- 实现过滤结果的可视化显示

**阶段 5**（1 周）：CLI 工具开发
- 创建命令行接口
- 支持配置文件

**阶段 6**（按需）：插件和集成功能

## 📝 实现细节

### 语言检测算法
```swift
func detectLanguage(_ text: String) -> DetectedLanguage {
    let chineseCharacterSet = CharacterSet(charactersIn: "\u{4e00}"..."\u{9fff}")
    let asciiCharacterSet = CharacterSet.alphanumerics

    let chineseCount = text.unicodeScalars.filter { chineseCharacterSet.contains($0) }.count
    let asciiCount = text.unicodeScalars.filter { asciiCharacterSet.contains($0) }.count
    let totalCount = text.count

    if totalCount == 0 { return .unknown }

    let chineseRatio = Double(chineseCount) / Double(totalCount)
    let asciiRatio = Double(asciiCount) / Double(totalCount)

    if chineseRatio > 0.3 && asciiRatio > 0.3 { return .mixed }
    if chineseRatio > 0.3 { return .chinese }
    if asciiRatio > 0.8 { return .english }
    if text.allSatisfy(\.isNumber) { return .numeric }

    return .unknown
}
```

这样既保持了项目的核心价值，又为未来扩展奠定了坚实基础，特别是在字符串过滤和分析方面提供了强大的功能。