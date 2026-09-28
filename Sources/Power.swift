import Foundation
import IOKit
import IOKit.ps

// 電源の読み取り。
//
// 出どころは AppleSmartBattery の登録内容。ioreg -rn AppleSmartBattery で見えるものと同じ。
// 一般ユーザーの権限で読める。
//
// 要る鍵だけを IORegistryEntryCreateCFProperty で取る。登録内容を丸ごと写すと、
// BatteryData のような大きい辞書まで毎回複製することになる。

/// 充電の状態
enum ChargeState: Equatable {
    /// 充電中
    case charging
    /// 電源につながっているが、充電器の電力が足りずバッテリーからも使っている
    case supplementing
    /// 本体の充電上限に達して止まっている。値は上限の %
    case heldAtLimit(Int)
    /// 満充電
    case full
    /// 電源につながっているが、上限以外の理由で充電していない
    case notCharging
    /// 電源につながっていない
    case onBattery

    var label: String {
        switch self {
        case .charging: return L.charging
        case .supplementing: return L.supplementing
        case .heldAtLimit(let limit): return L.heldAtLimit(limit)
        case .full: return L.full
        case .notCharging: return L.notCharging
        case .onBattery: return L.onBattery
        }
    }

    /// 生の値から状態を決める。画面にも IOKit にも触らない純粋な計算
    static func classify(
        connected: Bool, charging: Bool, full: Bool, percent: Int?, limit: Int?, batteryMilliamps: Int? = nil
    ) -> ChargeState {
        guard connected else { return .onBattery }
        // つながっているのにバッテリーから電流が出ている。充電器の電力を使い切っている
        if let batteryMilliamps, batteryMilliamps < Self.supplementingThreshold { return .supplementing }
        if charging { return .charging }
        if full || (percent ?? 0) >= 100 { return .full }
        // 上限で止まっている間も、残量は上限のすぐ下まで揺れる。本体は上限から数 % 落ちるまで
        // 充電を再開しない。上限から大きく下なら、止まっている理由は上限ではない
        if let limit, limit < 100, let percent, percent >= limit - Self.limitSlack {
            return .heldAtLimit(limit)
        }
        return .notCharging
    }

    /// 上限で止まっているとみなす幅
    static let limitSlack = 5

    /// バッテリーで補っているとみなす放電電流（mA）。計測の揺れで一瞬だけ負に振れる分は拾わない
    static let supplementingThreshold = -100
}

/// ある瞬間の電源の様子
struct PowerStatus {
    var isConnected = false
    var isCharging = false
    var isFullyCharged = false
    /// 残量（%）
    var batteryPercent: Int?
    /// 充電器の名前。例: 96W USB-C Power Adapter
    var chargerName: String?
    /// 充電器と取り決めた上限（W）
    var negotiatedWatts: Int?
    /// 充電器から Mac 全体に入っている電力（mW）
    var powerInMilliwatts: Int?
    /// 本体の充電上限（%）。設定していなければ nil
    var chargeLimit: Int?
    /// バッテリーに流れる電流（mA）。充電で正、放電で負
    var batteryMilliamps: Int?
    /// バッテリーの電圧（mV）
    var batteryMillivolts: Int?

    /// バッテリーから出ている電力（mW）。放電していなければ nil
    var batteryDrawMilliwatts: Int? {
        PowerFormat.dischargeMilliwatts(milliamps: batteryMilliamps, millivolts: batteryMillivolts)
    }

    var state: ChargeState {
        ChargeState.classify(
            connected: isConnected, charging: isCharging, full: isFullyCharged,
            percent: batteryPercent, limit: chargeLimit, batteryMilliamps: batteryMilliamps)
    }
}

/// 表示用の文字列の組み立て。画面にも IOKit にも触らない
enum PowerFormat {
    /// メニューバーの2段。
    /// - 充電器があるとき: 上が充電器から引いている電力、下が上限。例: 11W と 94W
    /// - 充電器が無いとき: 上がバッテリーから出ている電力、下は BAT。例: 8W と BAT
    /// - 抜いた直後でまだ放電の値が無いとき: 上が --、下は BAT
    /// バッテリーが無ければ nil を返し、呼ぶ側は1段で 0W と出す（Mac mini など）
    static func menuBar(
        powerInMilliwatts: Int?, negotiatedWatts: Int?, connected: Bool, batteryDrawMilliwatts: Int? = nil,
        batteryPresent: Bool = false
    ) -> (top: String, bottom: String)? {
        if connected {
            guard let negotiatedWatts, negotiatedWatts > 0 else { return nil }
            return ("\(wholeWatts(powerInMilliwatts ?? 0))W", "\(negotiatedWatts)W")
        }
        guard let batteryDrawMilliwatts else { return batteryPresent ? (pendingLabel, batteryLabel) : nil }
        return ("\(wholeWatts(batteryDrawMilliwatts))W", batteryLabel)
    }

    /// 抜いた直後の上の段。macOS は放電電流を1分ほど更新しないので、その間は値が無い。
    /// 0W と出すと「何も使っていない」と読めてしまうため、まだ分からないことを示す
    static let pendingLabel = "--"

    /// 充電器が無いときの下の段。英語の略だが日本語の表示でも通じる
    static let batteryLabel = "BAT"

    /// どちらの値も読めないときの1段の表示
    static let disconnected = "0W"

    /// 放電中の電力（mW）。電圧 × 放電電流。放電していない（電流が 0 以上）なら nil
    static func dischargeMilliwatts(milliamps: Int?, millivolts: Int?) -> Int? {
        guard let milliamps, let millivolts, milliamps < 0, millivolts > 0 else { return nil }
        return -milliamps * millivolts / 1000
    }

    /// mW を四捨五入した W にする。負の値は 0 に丸める（計測の揺れで一瞬だけ負になることがある）
    static func wholeWatts(_ milliwatts: Int) -> Int {
        Int((Double(max(milliwatts, 0)) / 1000).rounded())
    }

    /// ドロップダウン用。小数1桁まで出す。例: 11.8W
    static func detailWatts(_ milliwatts: Int) -> String {
        String(format: "%.1fW", Double(max(milliwatts, 0)) / 1000)
    }
}

enum PowerProbe {
    private static let chargingPolicyPath = "/Library/Preferences/com.apple.powerd.charging.plist"

    /// 全部読む。状態・充電器・上限の読み直しに使う
    static func current() -> PowerStatus {
        var status = PowerStatus()
        status.chargeLimit = chargeLimit()

        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        // バッテリーの無い Mac では見つからない。そのときは空のまま返す
        guard service != 0 else { return status }
        defer { IOObjectRelease(service) }

        status.isConnected = property("ExternalConnected", of: service) as? Bool ?? false
        status.isCharging = property("IsCharging", of: service) as? Bool ?? false
        status.isFullyCharged = property("FullyCharged", of: service) as? Bool ?? false
        status.batteryPercent = property("CurrentCapacity", of: service) as? Int
        // 放電中は負の値。ioreg は符号無しで表示するので 18446744073709550000 のような巨大な数に見えるが、
        // 中身は符号付きの 64 ビット。符号付きとして読み直す
        status.batteryMilliamps = amperage(of: service)
        status.batteryMillivolts = property("Voltage", of: service) as? Int
        status.powerInMilliwatts = powerIn(of: service)

        // 抜いた直後にも AdapterDetails が残っていることがある。つながっているときだけ使う
        if status.isConnected, let adapter = property("AdapterDetails", of: service) as? [String: Any] {
            status.negotiatedWatts = adapter["Watts"] as? Int
            status.chargerName = (adapter["Name"] as? String) ?? (adapter["Manufacturer"] as? String)
        }
        return status
    }

    /// 今の値だけ読む。2秒ごとに呼ぶので、要る鍵ひとつに絞る
    static func powerInMilliwatts() -> Int? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        return powerIn(of: service)
    }

    /// バッテリーの電流と電圧だけ読む。抜いている間、2秒ごとに呼ぶ
    static func battery() -> (milliamps: Int?, millivolts: Int?) {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return (nil, nil) }
        defer { IOObjectRelease(service) }
        return (amperage(of: service), property("Voltage", of: service) as? Int)
    }

    /// 放電中は負の値。ioreg は符号無しで表示するので 18446744073709550000 のような巨大な数に見えるが、
    /// 中身は符号付きの 64 ビット。符号付きとして読み直す
    private static func amperage(of service: io_service_t) -> Int? {
        (property("Amperage", of: service) as? NSNumber).map { Int($0.int64Value) }
    }

    private static func powerIn(of service: io_service_t) -> Int? {
        let telemetry = property("PowerTelemetryData", of: service) as? [String: Any]
        return telemetry?["SystemPowerIn"] as? Int
    }

    private static func property(_ key: String, of service: io_service_t) -> Any? {
        IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue()
    }

    // MARK: - 充電の上限

    /// 本体の「充電上限」。設定していなければ nil
    static func chargeLimit() -> Int? {
        guard
            let data = FileManager.default.contents(atPath: chargingPolicyPath),
            let root = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let policies = root["policies"] as? Data
        else { return nil }
        return chargeLimit(fromArchive: policies)
    }

    /// policies は NSKeyedArchiver で固めた ChargeCtrlPolicy の配列。そのクラスはこちらに無いので
    /// 解凍はせず plist として開き、soclimit を持ち、終わっていない（terminated が偽の）辞書を探す
    static func chargeLimit(fromArchive data: Data) -> Int? {
        guard
            let archive = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let objects = archive["$objects"] as? [Any]
        else { return nil }

        for case let policy as [String: Any] in objects {
            guard let limit = policy["soclimit"] as? Int else { continue }
            if policy["terminated"] as? Bool == true { continue }
            return limit
        }
        return nil
    }
}
