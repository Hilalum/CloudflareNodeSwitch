import XCTest
@testable import CloudflareNodeSwitch

final class CountryUtilsTests: XCTestCase {

    // MARK: - Flag Generation

    func testFlagForValidCountryCode() {
        XCTAssertEqual(CountryUtils.flag(for: "US"), "🇺🇸")
        XCTAssertEqual(CountryUtils.flag(for: "CN"), "🇨🇳")
        XCTAssertEqual(CountryUtils.flag(for: "JP"), "🇯🇵")
        XCTAssertEqual(CountryUtils.flag(for: "GB"), "🇬🇧")
        XCTAssertEqual(CountryUtils.flag(for: "DE"), "🇩🇪")
    }

    func testFlagForLowercaseCode() {
        XCTAssertEqual(CountryUtils.flag(for: "us"), "🇺🇸")
        XCTAssertEqual(CountryUtils.flag(for: "cn"), "🇨🇳")
    }

    func testFlagForInvalidCode() {
        XCTAssertEqual(CountryUtils.flag(for: ""), "")
        XCTAssertEqual(CountryUtils.flag(for: "X"), "")
        XCTAssertEqual(CountryUtils.flag(for: "XXX"), "")
        XCTAssertEqual(CountryUtils.flag(for: "ZZ"), "")
    }

    // MARK: - Country Name

    func testChineseNameForKnownCode() {
        XCTAssertEqual(CountryUtils.name(for: "US"), "美国")
        XCTAssertEqual(CountryUtils.name(for: "CN"), "中国")
        XCTAssertEqual(CountryUtils.name(for: "JP"), "日本")
        XCTAssertEqual(CountryUtils.name(for: "GB"), "英国")
    }

    func testEnglishNameForKnownCode() {
        // Note: This test depends on the system locale
        // In non-Chinese locale, should return English names
        let name = CountryUtils.name(for: "US")
        XCTAssertTrue(name == "美国" || name == "United States",
                      "Expected Chinese or English name for US, got: \(name)")
    }

    func testNameForUnknownCode() {
        let name = CountryUtils.name(for: "ZZ")
        XCTAssertEqual(name, "ZZ")
    }

    // MARK: - Country Code Validation

    func testIsValidCountryCode() {
        XCTAssertTrue(CountryUtils.isValidCountryCode("US"))
        XCTAssertTrue(CountryUtils.isValidCountryCode("CN"))
        XCTAssertTrue(CountryUtils.isValidCountryCode("JP"))
        XCTAssertTrue(CountryUtils.isValidCountryCode("us"))
        XCTAssertTrue(CountryUtils.isValidCountryCode("cn"))
    }

    func testIsInvalidCountryCode() {
        XCTAssertFalse(CountryUtils.isValidCountryCode("ZZ"))
        XCTAssertFalse(CountryUtils.isValidCountryCode("XX"))
        XCTAssertFalse(CountryUtils.isValidCountryCode(""))
    }

    // MARK: - Extract Country from Name

    func testExtractCountryFromFlagEmoji() {
        // US flag + node name (no space between flag and text)
        let name1 = "🇺🇸US - Premium Node"
        XCTAssertEqual(CountryUtils.extractCountry(from: name1), "US")

        // CN flag + node name
        let name2 = "🇨🇳China Node"
        XCTAssertEqual(CountryUtils.extractCountry(from: name2), "CN")

        // JP flag alone
        let name3 = "🇯🇵"
        XCTAssertEqual(CountryUtils.extractCountry(from: name3), "JP")
    }

    func testExtractCountryFromBrackets() {
        XCTAssertEqual(CountryUtils.extractCountry(from: "[US] Premium Node"), "US")
        XCTAssertEqual(CountryUtils.extractCountry(from: "(JP) Japan Node"), "JP")
        XCTAssertEqual(CountryUtils.extractCountry(from: "[HK] Hong Kong"), "HK")
    }

    func testExtractCountryFromBracketsRejectsInvalidCode() {
        XCTAssertNil(CountryUtils.extractCountry(from: "[ZZ] Invalid"))
        XCTAssertNil(CountryUtils.extractCountry(from: "(XX) Invalid"))
    }

    func testExtractCountryFromPrefix() {
        XCTAssertEqual(CountryUtils.extractCountry(from: "US Node Name"), "US")
        XCTAssertEqual(CountryUtils.extractCountry(from: "JP - Tokyo"), "JP")
        XCTAssertEqual(CountryUtils.extractCountry(from: "HK Premium"), "HK")
    }

    func testExtractCountryFromSuffix() {
        XCTAssertEqual(CountryUtils.extractCountry(from: "Node Name - US"), "US")
        XCTAssertEqual(CountryUtils.extractCountry(from: "Tokyo - JP"), "JP")
        XCTAssertEqual(CountryUtils.extractCountry(from: "Node | HK"), "HK")
    }

    func testExtractCountryReturnsNilForUnknownName() {
        XCTAssertNil(CountryUtils.extractCountry(from: "Random Node Name"))
        XCTAssertNil(CountryUtils.extractCountry(from: "No Country Here"))
    }

    func testExtractCountryPrefersFlagOverBrackets() {
        // Flag should be detected first
        let name = "🇺🇸 [US] Node"
        XCTAssertEqual(CountryUtils.extractCountry(from: name), "US")
    }

    func testExtractCountryPrefersBracketsOverPrefix() {
        // Brackets should be detected before prefix
        let name = "[JP] Japan Premium Node"
        XCTAssertEqual(CountryUtils.extractCountry(from: name), "JP")
    }

    // MARK: - Common Proxy Node Names

    func testParseCommonProxyNodeNames() {
        // Cloudflare WARP style
        XCTAssertEqual(CountryUtils.extractCountry(from: "🇺🇸 CF US 01"), "US")

        // Format: Name - Country
        XCTAssertEqual(CountryUtils.extractCountry(from: "Premium - SG"), "SG")

        // Format: [Country] Name
        XCTAssertEqual(CountryUtils.extractCountry(from: "[KR] Seoul Node"), "KR")

        // Format: Country Name
        XCTAssertEqual(CountryUtils.extractCountry(from: "DE Frankfurt"), "DE")
    }

    // MARK: - Edge Cases

    func testExtractCountryFromEmptyString() {
        XCTAssertNil(CountryUtils.extractCountry(from: ""))
    }

    func testExtractCountryFromWhitespace() {
        XCTAssertNil(CountryUtils.extractCountry(from: "   "))
    }

    func testExtractCountryWithUnicodeName() {
        // Chinese characters in name
        let name = "东京节点 - JP"
        XCTAssertEqual(CountryUtils.extractCountry(from: name), "JP")
    }

    func testFlagForAllCommonCodes() {
        let codes = ["US", "CN", "JP", "KR", "GB", "DE", "FR", "SG", "HK", "TW", "AU", "CA"]
        for code in codes {
            let flag = CountryUtils.flag(for: code)
            XCTAssertFalse(flag.isEmpty, "Flag should not be empty for \(code)")
        }
    }
}
