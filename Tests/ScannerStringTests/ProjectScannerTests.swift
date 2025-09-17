import XCTest
@testable import ScannerString
import Foundation

final class ProjectScannerTests: XCTestCase {

    var scanner: ProjectScanner!
    var testFixturesPath: String!

    override func setUpWithError() throws {
        scanner = ProjectScanner()

        // 获取测试固定数据路径
        let bundle = Bundle(for: type(of: self))
        testFixturesPath = bundle.bundlePath + "/Contents/Resources/TestFixtures"

        // 如果在Package测试环境中，尝试不同的路径
        if !FileManager.default.fileExists(atPath: testFixturesPath) {
            let currentPath = FileManager.default.currentDirectoryPath
            testFixturesPath = currentPath + "/Tests/ScannerStringTests/TestFixtures"
        }
    }

    override func tearDownWithError() throws {
        scanner = nil
        testFixturesPath = nil
    }

    func testScannerInitialization() {
        XCTAssertNotNil(scanner)
    }

    func testGetScanResultsEmpty() {
        let results = scanner.getScanResults()
        XCTAssertTrue(results.isEmpty, "New scanner should have empty results")
    }

    func testScanTestFixtures() throws {
        // 跳过此测试如果测试文件不存在
        guard FileManager.default.fileExists(atPath: testFixturesPath) else {
            throw XCTSkip("Test fixtures directory not found at: \(testFixturesPath ?? "nil")")
        }

        // 执行扫描（注意：这会输出到stderr，在测试中是正常的）
        let originalStderr = dup(STDERR_FILENO)
        let devNull = open("/dev/null", O_WRONLY)
        dup2(devNull, STDERR_FILENO)

        scanner.scanProject(at: testFixturesPath)

        // 恢复stderr
        dup2(originalStderr, STDERR_FILENO)
        close(devNull)
        close(originalStderr)

        let results = scanner.getScanResults()

        // 验证扫描结果
        XCTAssertFalse(results.isEmpty, "Should find strings in test fixtures")

        // 验证结果包含预期的字符串
        let contents = results.map { $0.content }
        XCTAssertTrue(contents.contains("Hello World"), "Should find English string")
        XCTAssertTrue(contents.contains("你好世界"), "Should find Chinese string")

        // 验证本地化字符串检测
        let localizedResults = results.filter { $0.isLocalized }
        XCTAssertFalse(localizedResults.isEmpty, "Should find localized strings")

        // 验证结果排序（按文件名、行号、列号排序）
        let sortedResults = results.sorted {
            $0.file == $1.file ?
                ($0.line == $1.line ? $0.column < $1.column : $0.line < $1.line) :
                $0.file < $1.file
        }
        XCTAssertEqual(results, sortedResults, "Results should be sorted")
    }

    func testScanNonExistentDirectory() {
        let nonExistentPath = "/path/that/does/not/exist"

        // 重定向stderr以避免测试输出中的错误消息
        let originalStderr = dup(STDERR_FILENO)
        let devNull = open("/dev/null", O_WRONLY)
        dup2(devNull, STDERR_FILENO)

        scanner.scanProject(at: nonExistentPath)

        // 恢复stderr
        dup2(originalStderr, STDERR_FILENO)
        close(devNull)
        close(originalStderr)

        let results = scanner.getScanResults()
        XCTAssertTrue(results.isEmpty, "Should have no results for non-existent path")
    }

    func testScanEmptyDirectory() throws {
        // 创建临时空目录
        let tempDir = NSTemporaryDirectory() + UUID().uuidString
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(atPath: tempDir)
        }

        // 重定向stderr
        let originalStderr = dup(STDERR_FILENO)
        let devNull = open("/dev/null", O_WRONLY)
        dup2(devNull, STDERR_FILENO)

        scanner.scanProject(at: tempDir)

        // 恢复stderr
        dup2(originalStderr, STDERR_FILENO)
        close(devNull)
        close(originalStderr)

        let results = scanner.getScanResults()
        XCTAssertTrue(results.isEmpty, "Should have no results for empty directory")
    }
}