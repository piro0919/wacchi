import AppKit

// メニューバーの2段表示。
//
// NSStatusItem の title は1行しか出せないので、2行を絵として描く。
// テンプレート画像にしておけば、メニューバーの明暗に合わせて OS が色を付ける。
// テンプレートでは色は無視され、透明度だけが効く。下の段を薄くするのはその透明度で行う。

@MainActor
enum StackedTitle {
    /// メニューバーの厚み。これが上限
    private static let height: CGFloat = 22

    /// 上下で同じ書体にする。大きさか太さが違うと、同じ桁数でも幅が揃わず上下がずれて見える
    private static let font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)

    static func image(top: String, bottom: String) -> NSImage {
        let topText = NSAttributedString(
            string: top, attributes: [.font: font, .foregroundColor: NSColor.black])
        let bottomText = NSAttributedString(
            string: bottom,
            attributes: [.font: font, .foregroundColor: NSColor.black.withAlphaComponent(0.55)])

        let topSize = topText.size()
        let bottomSize = bottomText.size()
        let width = ceil(max(topSize.width, bottomSize.width))

        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { _ in
            // 右に揃える。桁が変わったときに、数字の末尾（W）の位置が動かない
            // 行の箱には字の上下に余白があるので、箱を枠から 1pt ずつはみ出させて段の間を空ける。
            // 数字には下に伸びる部分が無く、はみ出しても字は欠けない
            bottomText.draw(at: NSPoint(x: width - bottomSize.width, y: -1))
            topText.draw(at: NSPoint(x: width - topSize.width, y: height - topSize.height + 1))
            return true
        }
        image.isTemplate = true
        return image
    }
}
