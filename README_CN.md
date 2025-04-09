# ScannerString

一个强大的 Swift 字符串扫描工具，帮助您分析和管理 Swift 项目中的字符串。

## 功能特点

- 扫描 Swift 源代码文件中的字符串字面量和正则表达式
- 识别本地化字符串（NSLocalizedString）
- 为每个字符串提供详细的位置信息（文件、行号、列号）
- 并发文件扫描以提高性能
- JSON 输出格式，便于与其他工具集成
- 自动排除常见目录（如 Pods、Carthage、Tests 等）

## 系统要求

- Swift 5.0 或更高版本
- macOS 10.15 或更高版本

## 安装方法

1. 克隆仓库：
```bash
git clone https://github.com/aSynch1889/ScannerString.git
```

2. 构建项目：
```bash
cd ScannerString
swift build
```

## 使用方法

在您的项目目录上运行扫描器：
```bash
./ScannerString /path/to/your/project
```

工具将输出一个包含所有找到的字符串及其位置和本地化状态的 JSON 数组。

## 输出格式

扫描器输出的 JSON 格式如下：
```json
[
  {
    "file": "path/to/file.swift",
    "line": 42,
    "column": 10,
    "content": "Hello, World!",
    "isLocalized": true
  }
]
```

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](LICENSE) 文件。 