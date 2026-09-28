import Foundation

/// 画面を出さずに、計算だけを確かめる。`./Wacchi --selftest` で走る。
/// 触れるのは値の計算だけで、IOKit にも設定にも触らない。
@MainActor
enum SelfTest {

    private static var failures = 0

    static func run() -> Int32 {
        failures = 0

        // メニューバーの2段
        do {
            let lines = PowerFormat.menuBar(powerInMilliwatts: 11800, negotiatedWatts: 94, connected: true)
            check(lines?.now == "12W" && lines?.max == "94W", "上に今の値を四捨五入して、下に上限")
            check(
                PowerFormat.menuBar(powerInMilliwatts: 11400, negotiatedWatts: 94, connected: true)?.now
                    == "11W",
                "0.5 未満は切り捨てる")
            check(
                PowerFormat.menuBar(powerInMilliwatts: nil, negotiatedWatts: 94, connected: true)?.now
                    == "0W",
                "今の値が読めなければ 0W として出す")
            check(
                PowerFormat.menuBar(powerInMilliwatts: 11800, negotiatedWatts: 94, connected: false) == nil,
                "抜いていれば2段にしない")
            check(
                PowerFormat.menuBar(powerInMilliwatts: 11800, negotiatedWatts: nil, connected: true) == nil,
                "上限が読めなければ2段にしない")
            check(
                PowerFormat.menuBar(powerInMilliwatts: 11800, negotiatedWatts: 0, connected: true) == nil,
                "上限が 0 なら2段にしない")
        }

        // W への丸め
        do {
            check(PowerFormat.wholeWatts(0) == 0, "0 は 0")
            check(PowerFormat.wholeWatts(499) == 0, "0.499W は 0")
            check(PowerFormat.wholeWatts(500) == 1, "0.5W は 1")
            // 計測の揺れで一瞬だけ負になることがある。負の電力は出さない
            check(PowerFormat.wholeWatts(-300) == 0, "負は 0 に丸める")
            check(PowerFormat.detailWatts(11800) == "11.8W", "詳細は小数1桁")
            check(PowerFormat.detailWatts(-300) == "0.0W", "詳細でも負は 0")
        }

        // 充電の状態
        do {
            check(
                ChargeState.classify(connected: false, charging: true, full: false, percent: 50, limit: 80)
                    == .onBattery,
                "抜いていれば、ほかの値に関わらずバッテリー駆動")
            check(
                ChargeState.classify(connected: true, charging: true, full: false, percent: 50, limit: 80)
                    == .charging,
                "充電中")
            check(
                ChargeState.classify(connected: true, charging: false, full: false, percent: 80, limit: 80)
                    == .heldAtLimit(80),
                "上限ちょうどで止まっている")
            check(
                ChargeState.classify(connected: true, charging: false, full: false, percent: 77, limit: 80)
                    == .heldAtLimit(80),
                "上限のすぐ下まで揺れても、上限で止まっている扱い")
            check(
                ChargeState.classify(connected: true, charging: false, full: false, percent: 50, limit: 80)
                    == .notCharging,
                "上限から大きく下なら、止まっている理由は上限ではない")
            check(
                ChargeState.classify(connected: true, charging: false, full: false, percent: 80, limit: nil)
                    == .notCharging,
                "上限を設定していなければ、上限で止まっているとは言わない")
            check(
                ChargeState.classify(connected: true, charging: false, full: false, percent: 100, limit: 100)
                    == .full,
                "100% は満充電")
            check(
                ChargeState.classify(connected: true, charging: false, full: true, percent: 99, limit: nil)
                    == .full,
                "FullyCharged が立っていれば満充電")
            check(
                ChargeState.classify(
                    connected: true, charging: false, full: false, percent: 60, limit: 80, batteryMilliamps: -1500)
                    == .supplementing,
                "つながっていてバッテリーから電流が出ていれば、充電器だけでは足りない")
            check(
                ChargeState.classify(
                    connected: true, charging: true, full: false, percent: 60, limit: 80, batteryMilliamps: -1500)
                    == .supplementing,
                "充電中の印が立っていても、放電していれば足りない方を出す")
            check(
                ChargeState.classify(
                    connected: true, charging: false, full: false, percent: 80, limit: 80, batteryMilliamps: -50)
                    == .heldAtLimit(80),
                "わずかな放電は揺れとみなし、足りないとは言わない")
            check(
                ChargeState.classify(
                    connected: false, charging: false, full: false, percent: 60, limit: 80, batteryMilliamps: -1500)
                    == .onBattery,
                "抜いていればバッテリー駆動。放電していて当然なので足りないとは言わない")
        }

        // 充電の上限の読み取り。NSKeyedArchiver の形を plist で組んで渡す
        do {
            check(PowerProbe.chargeLimit(fromArchive: archive([policy(80, terminated: false)])) == 80, "上限を読む")
            check(
                PowerProbe.chargeLimit(fromArchive: archive([policy(90, terminated: true)])) == nil,
                "終わった上限は使わない")
            check(
                PowerProbe.chargeLimit(
                    fromArchive: archive([policy(90, terminated: true), policy(80, terminated: false)])) == 80,
                "終わっていないほうを使う")
            check(PowerProbe.chargeLimit(fromArchive: archive([])) == nil, "上限が無ければ nil")
            check(PowerProbe.chargeLimit(fromArchive: Data("broken".utf8)) == nil, "壊れていれば nil")
        }

        // メニューに出す行の性質
        do {
            check(InfoRow.state.isFixed, "状態の行は隠せない")
            check(InfoRow.allCases.filter(\.isFixed).count == 1, "隠せない行はひとつだけ")
        }

        print(failures == 0 ? "全部通りました" : "\(failures) 件こけました")
        return failures == 0 ? 0 : 1
    }

    /// 実物の policies と同じ形。$objects の中に、クラスの参照や文字列と並んで上限の辞書が入る
    private static func archive(_ policies: [[String: Any]]) -> Data {
        let objects: [Any] = ["$null", "manualChargeLimit"] + policies
        let root: [String: Any] = ["$archiver": "NSKeyedArchiver", "$objects": objects, "$version": 100000]
        return try! PropertyListSerialization.data(fromPropertyList: root, format: .binary, options: 0)
    }

    private static func policy(_ limit: Int, terminated: Bool) -> [String: Any] {
        ["soclimit": limit, "terminated": terminated, "drain": true, "isEndOfCharge": true]
    }

    private static func check(_ condition: Bool, _ what: String) {
        if condition {
            print("  ok   \(what)")
        } else {
            print("  NG   \(what)")
            failures += 1
        }
    }
}
