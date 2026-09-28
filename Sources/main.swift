import AppKit
import IOKit.ps

// メニューバーの常駐。
//
// Konechi と同じく AppKit で組んでいる。メニューの中身は OS 側のメニューとして描かれるため、
// SwiftUI の MenuBarExtra からは開閉の通知が取れない。開いた瞬間に読み直したいので、開閉を知る必要がある。

@main
enum Wacchi {
    static func main() {
        // 画面を出さずに計算だけ確かめる口。直したあとはこれを通す
        if CommandLine.arguments.contains("--selftest") {
            exit(SelfTest.run())
        }
        // 読み取りの中身をそのまま出す口。表示がおかしいときはまずこれを見る
        if CommandLine.arguments.contains("--probe") {
            Probe.print()
            exit(0)
        }
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        // Dock とアプリ切替に出さず、メニューバーだけに常駐する
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()

    private var status = PowerStatus()
    /// 今の値だけを読む。2秒ごと
    private var powerTimer: Timer?
    /// 全部を読み直す保険。抜き挿しの通知を取りこぼしたとき用
    private var statusTimer: Timer?
    private var powerSource: CFRunLoopSource?
    /// いまメニューバーに出している中身。同じなら描き直さない
    private var shownTitle: String?

    private var settingsWindow = SettingsWindowController()
    /// 画面を作り直すかの判断に使う。文字列は組み立て時に焼き込まれるため
    private var builtLanguage = Language.resolved

    private let infoItems = Dictionary(
        uniqueKeysWithValues: InfoRow.allCases.map { ($0, NSMenuItem()) })

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.menu = menu
        // 充電器が無いときの 0W だけは文字で出す。2段の絵と同じく数字の幅を揃えておく
        statusItem.button?.font = .monospacedDigitSystemFont(
            ofSize: NSFont.menuBarFont(ofSize: 0).pointSize, weight: .regular)

        refreshAll()

        // 電源の抜き挿し。C の呼び戻しなので何も捕まえられない。通知に載せ替えて受ける
        powerSource = IOPSNotificationCreateRunLoopSource(
            { _ in NotificationCenter.default.post(name: .powerSourceChanged, object: nil) }, nil)?
            .takeRetainedValue()
        if let powerSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), powerSource, .defaultMode)
        }
        NotificationCenter.default.addObserver(
            forName: .powerSourceChanged, object: nil, queue: .main
        ) { [weak self] _ in
            // queue: .main を指定しているので主で呼ばれる。飛ばずに入る
            MainActor.assumeIsolated { self?.refreshAll() }
        }

        NotificationCenter.default.addObserver(
            forName: .settingsChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.builtLanguage != Language.resolved {
                    self.builtLanguage = Language.resolved
                    let wasVisible = self.settingsWindow.window?.isVisible ?? false
                    self.settingsWindow.close()
                    self.settingsWindow = SettingsWindowController()
                    if wasVisible { self.settingsWindow.show() }
                }
                self.buildMenu()
                self.refreshAll()
            }
        }

        // メニューを開いている間は通常の実行ループが止まる。.common に載せて、開いていても動かす
        powerTimer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            // Timer は主の実行ループから呼ぶ。飛ばずに入り、違ったら落とす
            MainActor.assumeIsolated { self?.refreshPower() }
        }
        statusTimer = Timer(timeInterval: 10, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshAll() }
        }
        for timer in [powerTimer, statusTimer].compactMap({ $0 }) {
            // 起こす時刻に幅を持たせ、OS がほかの仕事とまとめて起こせるようにする
            timer.tolerance = 0.5
            RunLoop.main.add(timer, forMode: .common)
        }

        // 更新の確認は起動時に1回だけ。見つかったときだけ画面が出る
        Updater.shared.checkQuietly()

        // メニューを押さずに設定画面を出すための入口。見た目を確かめるときに使う
        if CommandLine.arguments.contains("--settings") {
            openSettings()
        }
    }

    // MARK: - メニュー

    /// 出す項目は設定で変えられるので、変わるたびに組み直す
    private func buildMenu() {
        menu.delegate = self
        menu.removeAllItems()

        let visible = InfoRow.allCases.filter(Settings.isVisible)
        for row in visible {
            let item = infoItems[row]!
            item.isEnabled = false
            menu.addItem(item)
        }
        if !visible.isEmpty { menu.addItem(.separator()) }

        let settings = NSMenuItem(
            title: L.settings, action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(
            withTitle: L.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    /// 開いた瞬間の値を出す。次の読み直しを待たない
    func menuWillOpen(_ menu: NSMenu) {
        refreshAll()
    }

    // MARK: - 表示の更新

    private func refreshAll() {
        status = PowerProbe.current()
        render()
    }

    private func refreshPower() {
        if status.isConnected {
            status.powerInMilliwatts = PowerProbe.powerInMilliwatts()
        } else {
            // 抜いている間はバッテリーから出ている電力を出す。電流と電圧の2つだけ読む
            let battery = PowerProbe.battery()
            status.batteryMilliamps = battery.milliamps
            status.batteryMillivolts = battery.millivolts
        }
        render()
    }

    private func render() {
        let lines = PowerFormat.menuBar(
            powerInMilliwatts: status.powerInMilliwatts, negotiatedWatts: status.negotiatedWatts,
            connected: status.isConnected, batteryDrawMilliwatts: status.batteryDrawMilliwatts,
            batteryPresent: status.batteryMillivolts != nil)
        // 同じものを入れ直すだけでもメニューバーは描き直される。変わったときだけ入れる
        let key = lines.map { "\($0.top)\n\($0.bottom)" } ?? PowerFormat.disconnected
        if key != shownTitle {
            shownTitle = key
            if let lines {
                statusItem.button?.title = ""
                statusItem.button?.image = StackedTitle.image(top: lines.top, bottom: lines.bottom)
            } else {
                statusItem.button?.image = nil
                statusItem.button?.title = PowerFormat.disconnected
            }
        }
        statusItem.button?.toolTip = status.state.label

        setInfo(.state, "\(L.state): \(status.state.label)")
        setInfo(.battery, "\(L.battery): \(status.batteryPercent.map { "\($0)%" } ?? "-")")
        setInfo(.charger, "\(L.charger): \(status.chargerName ?? "-")")
        setInfo(.negotiated, "\(L.negotiated): \(status.negotiatedWatts.map { "\($0)W" } ?? "-")")
        let powerIn: String? =
            status.isConnected
            ? status.powerInMilliwatts.map(PowerFormat.detailWatts)
            : status.batteryDrawMilliwatts.map { PowerFormat.detailWatts($0) + L.fromBattery }
        setInfo(.powerIn, "\(L.powerIn): \(powerIn ?? "-")")
    }

    /// 情報の行は一段小さい文字で出す。文字数を削らずに幅が縮み、操作の行とも区別が付く
    private func setInfo(_ row: InfoRow, _ text: String) {
        let item = infoItems[row]!
        // 閉じている間も2秒ごとに呼ばれる。同じ文字なら組み直さない
        if item.attributedTitle?.string == text { return }
        item.attributedTitle = NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.menuFont(ofSize: 12),
                .foregroundColor: NSColor.secondaryLabelColor,
            ])
    }

    @objc private func openSettings() {
        settingsWindow.show()
    }
}

/// --probe の中身。読み取った生の値と、そこから決めた表示を並べる
enum Probe {
    static func print() {
        let status = PowerProbe.current()
        let lines = [
            "ExternalConnected   \(status.isConnected)",
            "IsCharging          \(status.isCharging)",
            "FullyCharged        \(status.isFullyCharged)",
            "CurrentCapacity     \(status.batteryPercent.map(String.init) ?? "nil")",
            "AdapterDetails.Name \(status.chargerName ?? "nil")",
            "AdapterDetails.Watts \(status.negotiatedWatts.map(String.init) ?? "nil")",
            "SystemPowerIn (mW)  \(status.powerInMilliwatts.map(String.init) ?? "nil")",
            "soclimit            \(status.chargeLimit.map(String.init) ?? "nil")",
            "Amperage (mA)       \(status.batteryMilliamps.map(String.init) ?? "nil")",
            "Voltage (mV)        \(status.batteryMillivolts.map(String.init) ?? "nil")",
            "",
            "menu bar            \(menuBar(status))",
            "state               \(status.state)",
        ]
        Swift.print(lines.joined(separator: "\n"))
    }

    private static func menuBar(_ status: PowerStatus) -> String {
        guard
            let lines = PowerFormat.menuBar(
                powerInMilliwatts: status.powerInMilliwatts, negotiatedWatts: status.negotiatedWatts,
                connected: status.isConnected, batteryDrawMilliwatts: status.batteryDrawMilliwatts,
                batteryPresent: status.batteryMillivolts != nil)
        else { return PowerFormat.disconnected }
        return "\(lines.top) (top) / \(lines.bottom) (bottom)"
    }
}
