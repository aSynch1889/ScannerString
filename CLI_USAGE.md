# ScannerString CLI Tool

## 🚀 安装和构建

### 构建 CLI 工具
```bash
# 在项目根目录下运行
swift build -c release

# 可执行文件将生成在:
.build/release/scannerstring
```

### 安装到系统路径（可选）
```bash
# 复制到 /usr/local/bin
sudo cp .build/release/scannerstring /usr/local/bin/

# 或创建符号链接
sudo ln -sf $(pwd)/.build/release/scannerstring /usr/local/bin/scannerstring
```

## 📖 使用方法

### 基本用法
```bash
# 扫描当前目录
scannerstring .

# 扫描指定项目路径
scannerstring /path/to/your/project

# 显示帮助信息
scannerstring --help
```

### 输出格式

#### JSON 输出（默认）
```bash
scannerstring . --format json
```

#### CSV 输出
```bash
scannerstring . --format csv --output results.csv
```

#### 纯文本输出
```bash
scannerstring . --format text
```

### 字符串过滤

#### 语言过滤
```bash
# 只扫描中文字符串
scannerstring . --languages chinese

# 扫描中文和英文字符串
scannerstring . --languages chinese english

# 扫描混合语言字符串
scannerstring . --languages mixed
```

#### 内容过滤
```bash
# 设置最小字符串长度
scannerstring . --min-length 3

# 排除重复字符串
scannerstring . --exclude-duplicates

# 排除空字符串
scannerstring . --exclude-empty

# 排除纯数字字符串
scannerstring . --exclude-numeric
```

#### 组合过滤
```bash
# 严格模式：中英文字符串，长度>=3，排除重复和数字
scannerstring . \
  --languages chinese english mixed \
  --min-length 3 \
  --exclude-duplicates \
  --exclude-numeric \
  --exclude-empty
```

### 统计信息

#### 显示过滤统计
```bash
scannerstring . --show-stats
```

输出示例：
```
🔍 Scanning project at: .

📊 Filter Statistics:
Original count: 1247
Filtered count: 356
Filter ratio: 71.4%
Processing time: 0.12s

Filter steps:
  LanguageFilter: 1247 → 892 (0.05s)
  ContentFilter: 892 → 445 (0.03s)
  DuplicateFilter: 445 → 356 (0.04s)
```

### 配置文件

#### 使用预设配置
```bash
# 使用配置文件
scannerstring . --config Examples/scannerstring-config.json

# 基础配置（包含中英文，长度>=2）
scannerstring . --config Examples/scannerstring-basic.json

# 本地化配置（专注中文和混合语言）
scannerstring . --config Examples/scannerstring-localization.json
```

#### 自定义配置文件
创建 `my-config.json`：
```json
{
  "languages": ["chinese", "english"],
  "minLength": 2,
  "excludeDuplicates": true,
  "excludeEmpty": true,
  "excludeNumeric": false
}
```

使用：
```bash
scannerstring . --config my-config.json
```

### 输出到文件

```bash
# 输出到 JSON 文件
scannerstring . --output results.json --show-stats

# 输出到 CSV 文件
scannerstring . --format csv --output results.csv

# 输出到文本文件
scannerstring . --format text --output results.txt
```

## 📊 输出格式详解

### JSON 输出格式
```json
{
  "results": [
    {
      "file": "Sources/ScannerString/Core.swift",
      "line": 42,
      "column": 16,
      "content": "Hello World",
      "isLocalized": false
    }
  ],
  "statistics": {
    "originalCount": 1247,
    "filteredCount": 356,
    "filterRatio": 0.714,
    "processingTime": 0.12,
    "filterSteps": [
      {
        "filterName": "LanguageFilter",
        "beforeCount": 1247,
        "afterCount": 892,
        "processingTime": 0.05
      }
    ]
  }
}
```

### CSV 输出格式
```csv
File,Line,Column,Content,IsLocalized
"Sources/ScannerString/Core.swift",42,16,"Hello World",false
"ScannerString/ContentView.swift",127,28,"扫描完成",false
```

### 文本输出格式
```
Sources/ScannerString/Core.swift:42:16: Hello World
ScannerString/ContentView.swift:127:28: 扫描完成
```

## 🎯 实际使用场景

### 1. 本地化项目分析
```bash
# 扫描需要翻译的中文字符串
scannerstring . \
  --languages chinese mixed \
  --exclude-empty \
  --format csv \
  --output localization-strings.csv
```

### 2. 代码质量检查
```bash
# 查找重复的硬编码字符串
scannerstring . \
  --exclude-duplicates \
  --show-stats \
  --format json \
  --output code-review.json
```

### 3. 字符串统计分析
```bash
# 生成详细的字符串使用报告
scannerstring . \
  --show-stats \
  --format json \
  --output string-analysis.json
```

## ⚡ 性能建议

- 大型项目建议使用配置文件避免命令行参数过长
- 使用 `--exclude-duplicates` 可以显著减少输出大小
- JSON 格式适合后续程序处理，CSV 格式适合 Excel 分析
- `--show-stats` 对性能分析和优化很有帮助

## 🔧 高级用法

### 结合其他工具使用
```bash
# 统计字符串数量
scannerstring . --format text | wc -l

# 查找特定内容
scannerstring . --format json | jq '.results[] | select(.content | contains("API"))'

# 按文件分组统计
scannerstring . --format csv | cut -d',' -f1 | sort | uniq -c
```