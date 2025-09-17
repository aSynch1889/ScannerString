import XCTest
@testable import ScannerString

final class StringLocationTests: XCTestCase {

    func testStringLocationEquality() {
        let location1 = StringLocation(
            file: "/path/to/file.swift",
            line: 10,
            column: 5,
            content: "Hello World",
            isLocalized: false
        )

        let location2 = StringLocation(
            file: "/path/to/file.swift",
            line: 10,
            column: 5,
            content: "Hello World",
            isLocalized: false
        )

        let location3 = StringLocation(
            file: "/path/to/file.swift",
            line: 10,
            column: 5,
            content: "Different Content",
            isLocalized: false
        )

        XCTAssertEqual(location1, location2)
        XCTAssertNotEqual(location1, location3)
    }

    func testStringLocationHashing() {
        let location1 = StringLocation(
            file: "/path/to/file.swift",
            line: 10,
            column: 5,
            content: "Hello World",
            isLocalized: false
        )

        let location2 = StringLocation(
            file: "/path/to/file.swift",
            line: 10,
            column: 5,
            content: "Hello World",
            isLocalized: false
        )

        XCTAssertEqual(location1.hashValue, location2.hashValue)
    }

    func testStringLocationCoding() throws {
        let original = StringLocation(
            file: "/path/to/file.swift",
            line: 42,
            column: 15,
            content: "Test String 测试",
            isLocalized: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StringLocation.self, from: data)

        XCTAssertEqual(original, decoded)
        XCTAssertEqual(original.file, decoded.file)
        XCTAssertEqual(original.line, decoded.line)
        XCTAssertEqual(original.column, decoded.column)
        XCTAssertEqual(original.content, decoded.content)
        XCTAssertEqual(original.isLocalized, decoded.isLocalized)
    }

    func testStringLocationWithDifferentCharacters() {
        let chineseLocation = StringLocation(
            file: "/path/测试.swift",
            line: 1,
            column: 1,
            content: "你好世界",
            isLocalized: false
        )

        let emojiLocation = StringLocation(
            file: "/path/emoji.swift",
            line: 1,
            column: 1,
            content: "Hello 🌍",
            isLocalized: false
        )

        XCTAssertFalse(chineseLocation.content.isEmpty)
        XCTAssertFalse(emojiLocation.content.isEmpty)
        XCTAssertNotEqual(chineseLocation, emojiLocation)
    }
}