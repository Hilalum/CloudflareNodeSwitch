import Foundation

/// 国家工具：国家代码到国旗 emoji、中文名称的映射
enum CountryUtils {
    /// 国家代码到国旗 emoji
    static func flag(for countryCode: String) -> String {
        let code = countryCode.uppercased()
        guard code.count == 2, isValidCountryCode(code) else { return "" }
        let base: UInt32 = 0x1F1E6 - 65 // regional indicator symbol letter A
        var flag = ""
        for scalar in code.unicodeScalars {
            guard let ri = Unicode.Scalar(base + scalar.value) else { continue }
            flag.append(String(ri))
        }
        return flag
    }

    /// 国家代码到中文名称
    static let chineseNames: [String: String] = [
        "US": "美国", "CN": "中国", "JP": "日本", "KR": "韩国",
        "GB": "英国", "DE": "德国", "FR": "法国", "IT": "意大利",
        "ES": "西班牙", "PT": "葡萄牙", "NL": "荷兰", "BE": "比利时",
        "CH": "瑞士", "AT": "奥地利", "SE": "瑞典", "NO": "挪威",
        "DK": "丹麦", "FI": "芬兰", "PL": "波兰", "CZ": "捷克",
        "RO": "罗马尼亚", "HU": "匈牙利", "BG": "保加利亚", "HR": "克罗地亚",
        "SK": "斯洛伐克", "SI": "斯洛文尼亚", "LT": "立陶宛", "LV": "拉脱维亚",
        "EE": "爱沙尼亚", "IE": "爱尔兰", "GR": "希腊", "TR": "土耳其",
        "RU": "俄罗斯", "UA": "乌克兰", "BY": "白俄罗斯", "KZ": "哈萨克斯坦",
        "UZ": "乌兹别克斯坦", "IN": "印度", "PK": "巴基斯坦", "BD": "孟加拉",
        "LK": "斯里兰卡", "NP": "尼泊尔", "TH": "泰国", "VN": "越南",
        "ID": "印度尼西亚", "MY": "马来西亚", "SG": "新加坡", "PH": "菲律宾",
        "KH": "柬埔寨", "MM": "缅甸", "LA": "老挝", "MO": "澳门",
        "HK": "香港", "TW": "台湾", "MN": "蒙古", "AU": "澳大利亚",
        "NZ": "新西兰", "CA": "加拿大", "MX": "墨西哥", "BR": "巴西",
        "AR": "阿根廷", "CL": "智利", "CO": "哥伦比亚", "PE": "秘鲁",
        "VE": "委内瑞拉", "EC": "厄瓜多尔", "ZA": "南非", "EG": "埃及",
        "NG": "尼日利亚", "KE": "肯尼亚", "GH": "加纳", "IL": "以色列",
        "AE": "阿联酋", "SA": "沙特阿拉伯", "QA": "卡塔尔", "KW": "科威特",
        "BH": "巴林", "OM": "阿曼", "JO": "约旦", "LB": "黎巴嫩",
        "IQ": "伊拉克", "IR": "伊朗", "SY": "叙利亚", "AF": "阿富汗",
        "KP": "朝鲜",
    ]

    /// 国家代码到英文名称
    static let englishNames: [String: String] = [
        "US": "United States", "CN": "China", "JP": "Japan", "KR": "South Korea",
        "GB": "United Kingdom", "DE": "Germany", "FR": "France", "IT": "Italy",
        "ES": "Spain", "PT": "Portugal", "NL": "Netherlands", "BE": "Belgium",
        "CH": "Switzerland", "AT": "Austria", "SE": "Sweden", "NO": "Norway",
        "DK": "Denmark", "FI": "Finland", "PL": "Poland", "CZ": "Czechia",
        "RO": "Romania", "HU": "Hungary", "BG": "Bulgaria", "HR": "Croatia",
        "SK": "Slovakia", "SI": "Slovenia", "LT": "Lithuania", "LV": "Latvia",
        "EE": "Estonia", "IE": "Ireland", "GR": "Greece", "TR": "Turkey",
        "RU": "Russia", "UA": "Ukraine", "BY": "Belarus", "KZ": "Kazakhstan",
        "UZ": "Uzbekistan", "IN": "India", "PK": "Pakistan", "BD": "Bangladesh",
        "LK": "Sri Lanka", "NP": "Nepal", "TH": "Thailand", "VN": "Vietnam",
        "ID": "Indonesia", "MY": "Malaysia", "SG": "Singapore", "PH": "Philippines",
        "KH": "Cambodia", "MM": "Myanmar", "LA": "Laos", "MO": "Macau",
        "HK": "Hong Kong", "TW": "Taiwan", "MN": "Mongolia",
        "AU": "Australia", "NZ": "New Zealand", "CA": "Canada", "MX": "Mexico",
        "BR": "Brazil", "AR": "Argentina", "CL": "Chile", "CO": "Colombia",
        "PE": "Peru", "VE": "Venezuela", "EC": "Ecuador",
        "ZA": "South Africa", "EG": "Egypt", "NG": "Nigeria", "KE": "Kenya",
        "GH": "Ghana", "IL": "Israel", "AE": "UAE", "SA": "Saudi Arabia",
        "QA": "Qatar", "KW": "Kuwait", "BH": "Bahrain", "OM": "Oman",
        "JO": "Jordan", "LB": "Lebanon", "IQ": "Iraq", "IR": "Iran",
        "SY": "Syria", "AF": "Afghanistan", "KP": "North Korea",
    ]

    /// 合并的国家代码集合，用于快速验证
    private static let validCountryCodes: Set<String> = {
        Set(chineseNames.keys).union(englishNames.keys)
    }()

    /// 预编译的正则表达式
    private static let bracketRegex = try? NSRegularExpression(pattern: #"^[\[\(]([A-Za-z]{2})[\]\)]"#)
    private static let suffixDashRegex = try? NSRegularExpression(pattern: #"-\s*([A-Za-z]{2})\s*$"#)
    private static let suffixPipeRegex = try? NSRegularExpression(pattern: #"\|\s*([A-Za-z]{2})\s*$"#)

    /// 验证是否为已知国家代码
    static func isValidCountryCode(_ code: String) -> Bool {
        validCountryCodes.contains(code.uppercased())
    }

    /// 根据系统语言返回国家中文名或英文名
    static func name(for countryCode: String) -> String {
        let code = countryCode.uppercased()
        if LocalizedString.isChinese {
            return chineseNames[code] ?? code
        }
        return englishNames[code] ?? code
    }

    /// 从节点名称中解析国家代码
    /// 支持格式：
    /// - 🇺🇸 US - Node Name
    /// - Node Name - US
    /// - [US] Node Name
    /// - (日本) Node Name
    /// - US Node Name
    static func extractCountry(from name: String) -> String? {
        // 1. 检查 emoji 国旗开头
        if let code = extractCountryFromFlag(name) {
            return code
        }

        // 2. 检查 [XX] 或 (XX) 格式
        if let code = extractCountryFromBrackets(name) {
            return code
        }

        // 3. 检查名称开头的 2-3 个大写字母（如 US、JP、HK）
        if let code = extractCountryFromPrefix(name) {
            return code
        }

        // 4. 检查名称结尾的国家代码
        if let code = extractCountryFromSuffix(name) {
            return code
        }

        return nil
    }

    private static func extractCountryFromFlag(_ name: String) -> String? {
        let scalars = Array(name.unicodeScalars)
        guard scalars.count >= 2 else { return nil }

        let base: UInt32 = 0x1F1E6 - 65
        let riEnd: UInt32 = 0x1F1FF // regional indicator symbol letter Z
        var codes: [Character] = []

        for scalar in scalars.prefix(4) { // 国旗 emoji 最多 4 个 unicode scalar
            let val = scalar.value
            if val >= base && val <= riEnd {
                codes.append(Character(Unicode.Scalar(val - base + 65)!))
            } else if !codes.isEmpty {
                break
            }
        }

        if codes.count == 2 {
            let code = String(codes).uppercased()
            // 验证是已知国家代码
            if isValidCountryCode(code) {
                return code
            }
        }
        return nil
    }

    private static func extractCountryFromBrackets(_ name: String) -> String? {
        guard let regex = bracketRegex else { return nil }
        guard let match = regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)),
              let range = Range(match.range(at: 1), in: name) else {
            return nil
        }
        let code = String(name[range]).uppercased()
        // 验证是已知国家代码
        guard isValidCountryCode(code) else { return nil }
        return code
    }

    private static func extractCountryFromPrefix(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        // Skip if starts with emoji (regional indicator: U+1F1E6 ~ U+1F1FF)
        if let firstScalar = trimmed.unicodeScalars.first,
           firstScalar.value >= 0x1F1E6 && firstScalar.value <= 0x1F1FF {
            return nil
        }

        let words = trimmed.components(separatedBy: .whitespaces)
        guard let first = words.first, first.count >= 2, first.count <= 3 else { return nil }

        // Check if all characters are uppercase letters
        guard first.allSatisfy({ $0.isUppercase && $0.isLetter }) else { return nil }

        let code = first.uppercased()
        // Verify it's a known country code
        guard isValidCountryCode(code) else { return nil }
        return code
    }

    private static func extractCountryFromSuffix(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        let patterns: [(NSRegularExpression?, String)] = [
            (suffixDashRegex, "-"),
            (suffixPipeRegex, "|"),
        ]

        for (regex, _) in patterns {
            guard let regex else { continue }
            if let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
               let range = Range(match.range(at: 1), in: trimmed) {
                let code = String(trimmed[range]).uppercased()
                guard isValidCountryCode(code) else { continue }
                return code
            }
        }
        return nil
    }
}
