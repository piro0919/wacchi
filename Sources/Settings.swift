import Foundation
import ServiceManagement

// 設定の保存と読み出し。
//
// 数が少ないので UserDefaults に直接置く。ログイン時の起動だけは OS 側が持つ状態なので、
// こちらでは持たず ServiceManagement に問い合わせる。二重に持つと必ずずれる。

/// メニューに出す情報の行
enum InfoRow: String, CaseIterable {
    case state, battery, charger, negotiated, powerIn

    var label: String {
        switch self {
        case .state: return L.state
        case .battery: return L.battery
        case .charger: return L.charger
        case .negotiated: return L.negotiated
        case .powerIn: return L.powerIn
        }
    }

    /// 状態はこのアプリの本体なので隠せない
    var isFixed: Bool { self == .state }
}

enum Settings {
    private static let hiddenRowsKey = "hiddenInfoRows"
    private static let languageKey = "language"

    // MARK: - 言語

    /// 既定は「システムに従う」。実際にどちらを使うかは Language.resolved が決める
    static var language: Language {
        get {
            UserDefaults.standard.string(forKey: languageKey)
                .flatMap(Language.init(rawValue:)) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    // MARK: - メニューに出す項目

    /// 隠している行。既定は「全部出す」なので、保存するのは隠したものだけにする。
    /// 出すものを保存すると、後から行が増えたときに既存の利用者へ出なくなる
    static var hiddenRows: Set<InfoRow> {
        get {
            let saved = UserDefaults.standard.stringArray(forKey: hiddenRowsKey) ?? []
            return Set(saved.compactMap(InfoRow.init(rawValue:)).filter { !$0.isFixed })
        }
        set {
            UserDefaults.standard.set(
                newValue.filter { !$0.isFixed }.map(\.rawValue), forKey: hiddenRowsKey)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    static func isVisible(_ row: InfoRow) -> Bool {
        !hiddenRows.contains(row)
    }

    static func setVisible(_ row: InfoRow, _ visible: Bool) {
        var rows = hiddenRows
        if visible { rows.remove(row) } else { rows.insert(row) }
        hiddenRows = rows
    }

    // MARK: - ログイン時の起動

    /// 状態は OS 側が持っているので、こちらでは覚えず毎回問い合わせる
    static var launchesAtLogin: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// 切り替えに失敗したら理由を返す。成功なら nil
    static func setLaunchesAtLogin(_ enabled: Bool) -> String? {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("wacchi.settingsChanged")
    static let powerSourceChanged = Notification.Name("wacchi.powerSourceChanged")
}
