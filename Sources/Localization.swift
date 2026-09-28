import Foundation

// 表示文字列。
//
// .lproj は使わず Swift の表に置く。ビルドを自前の shell で組んでいて、
// 文字列だけのために資源の仕組みを足すと build.sh が重くなるため。
// 言語は2つしかないので、この形のほうが追いやすい。

enum Language: String, CaseIterable {
    case system, ja, en

    /// 実際に使う言語。既定は英語で、環境が日本語のときだけ日本語にする
    static var resolved: Language {
        switch Settings.language {
        case .ja: return .ja
        case .en: return .en
        case .system:
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.hasPrefix("ja") ? .ja : .en
        }
    }

    var label: String {
        switch self {
        case .system: return L.t("システムに従う", "Follow system")
        case .ja: return "日本語"
        case .en: return "English"
        }
    }
}

enum L {
    static func t(_ ja: String, _ en: String) -> String {
        Language.resolved == .ja ? ja : en
    }

    // 充電の状態
    static var charging: String { t("充電中", "Charging") }
    static var supplementing: String { t("充電器だけでは足りず、バッテリーも使用中", "Charger can't keep up, using battery too") }
    static func heldAtLimit(_ limit: Int) -> String {
        t("上限 \(limit)% で停止中", "Held at the \(limit)% limit")
    }
    static var full: String { t("満充電", "Fully charged") }
    static var notCharging: String { t("充電していない", "Not charging") }
    static var onBattery: String { t("バッテリー駆動", "On battery") }

    // メニュー
    static var state: String { t("状態", "Status") }
    static var battery: String { t("残量", "Battery") }
    static var charger: String { t("充電器", "Charger") }
    static var negotiated: String { t("最大", "Max") }
    static var powerIn: String { t("今の電力", "Drawing") }
    static var fromBattery: String { t("（バッテリーから）", " (from battery)") }
    static var settings: String { t("設定…", "Settings…") }
    static var quit: String { t("終了", "Quit") }

    // 設定画面
    static var settingsTitle: String { t("Wacchi の設定", "Wacchi Settings") }
    static var launchAtLogin: String { t("ログイン時に起動する", "Launch at login") }
    static var visibleRows: String { t("メニューに出す項目", "Rows shown in the menu") }
    static var language: String { t("言語", "Language") }
    static var checkForUpdates: String { t("更新を確認", "Check for updates") }
    static func launchToggleFailed(_ reason: String) -> String {
        t("切り替えられませんでした: \(reason)", "Could not change it: \(reason)")
    }
}
