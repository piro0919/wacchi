import AppKit

// 設定画面。
//
// 項目が少ないので xib は使わず、素の NSView に積む。
// 言語を変えると文字列が全部変わるので、そのときは画面ごと作り直す。

@MainActor
final class SettingsWindowController: NSWindowController {
    private let launchCheckbox = NSButton(checkboxWithTitle: L.launchAtLogin, target: nil, action: nil)
    private let languagePopUp = NSPopUpButton()
    private let messageLabel = NSTextField(labelWithString: "")

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)
        window.title = L.settingsTitle
        window.isReleasedWhenClosed = false
        self.init(window: window)
        build()
    }

    private func build() {
        guard let window else { return }

        let version =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"

        launchCheckbox.target = self
        launchCheckbox.action = #selector(toggleLaunch)
        launchCheckbox.state = Settings.launchesAtLogin ? .on : .off

        messageLabel.textColor = .systemRed
        messageLabel.font = .systemFont(ofSize: 11)
        // 文字が無いときは畳む。空のまま置くと、その行のぶんだけ間延びする
        messageLabel.isHidden = true

        languagePopUp.target = self
        languagePopUp.action = #selector(changeLanguage)
        for language in Language.allCases {
            languagePopUp.addItem(withTitle: language.label)
        }
        languagePopUp.selectItem(at: Language.allCases.firstIndex(of: Settings.language) ?? 0)

        let languageRow = row(L.language, languagePopUp)

        let updateButton = NSButton(
            title: L.checkForUpdates, target: self, action: #selector(checkForUpdates))
        updateButton.bezelStyle = .rounded

        let about = NSTextField(labelWithString: "Wacchi \(version)")
        about.textColor = .secondaryLabelColor
        about.font = .systemFont(ofSize: 11)

        let stack = NSStackView(views: [
            launchCheckbox, languageRow, messageLabel, rowsSection(), updateButton, about,
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        // 余白は枠との距離として直接指定する。積み上げ側の余白指定は、
        // 窓の幅を中身から決めるときに右側が勘定に入らず、右端が詰まった
        let margin: CGFloat = 24
        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: margin),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: margin),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -margin),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -margin),
        ])
        window.contentView = content
        content.layoutSubtreeIfNeeded()
        window.setContentSize(content.fittingSize)
    }

    private func row(_ title: String, _ control: NSView) -> NSView {
        let stack = NSStackView(views: [NSTextField(labelWithString: title), control])
        stack.orientation = .horizontal
        stack.spacing = 12
        return stack
    }

    /// メニューに出す行の取捨。状態は隠せないので、印を付けたまま操作させない
    private func rowsSection() -> NSView {
        let title = NSTextField(labelWithString: L.visibleRows)
        title.font = .systemFont(ofSize: 12, weight: .semibold)

        var views: [NSView] = [title]
        for row in InfoRow.allCases {
            let checkbox = NSButton(
                checkboxWithTitle: row.label, target: self, action: #selector(toggleRow))
            checkbox.state = Settings.isVisible(row) ? .on : .off
            checkbox.isEnabled = !row.isFixed
            checkbox.tag = InfoRow.allCases.firstIndex(of: row)!
            views.append(checkbox)
        }

        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        return stack
    }

    func show() {
        // 状態は開くたびに読み直す。設定画面の外（システム設定）で変えられることがあるため
        launchCheckbox.state = Settings.launchesAtLogin ? .on : .off
        report("")

        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    @objc private func toggleLaunch() {
        let wanted = launchCheckbox.state == .on
        if let failure = Settings.setLaunchesAtLogin(wanted) {
            report(L.launchToggleFailed(failure))
            // OS 側が変わっていないので、見た目を実際の状態へ戻す
            launchCheckbox.state = Settings.launchesAtLogin ? .on : .off
            return
        }
        report("")
    }

    private func report(_ text: String) {
        messageLabel.stringValue = text
        messageLabel.isHidden = text.isEmpty
    }

    @objc private func toggleRow(_ sender: NSButton) {
        guard InfoRow.allCases.indices.contains(sender.tag) else { return }
        Settings.setVisible(InfoRow.allCases[sender.tag], sender.state == .on)
    }

    @objc private func checkForUpdates() {
        Updater.shared.checkNow()
    }

    @objc private func changeLanguage() {
        let index = languagePopUp.indexOfSelectedItem
        guard Language.allCases.indices.contains(index) else { return }
        Settings.language = Language.allCases[index]
    }
}
