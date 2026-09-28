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

    private static let topFont = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold)
    private static let bottomFont = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular)

    static func image(top: String, bottom: String) -> NSImage {
        let topText = NSAttributedString(
            string: top, attributes: [.font: topFont, .foregroundColor: NSColor.black])
        let bottomText = NSAttributedString(
            string: bottom,
            attributes: [.font: bottomFont, .foregroundColor: NSColor.black.withAlphaComponent(0.6)])

        let topSize = topText.size()
        let bottomSize = bottomText.size()
        let width = ceil(max(topSize.width, bottomSize.width))

        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { _ in
            // 右に揃える。桁が変わったときに、数字の末尾（W）の位置が動かない
            bottomText.draw(at: NSPoint(x: width - bottomSize.width, y: 1))
            topText.draw(at: NSPoint(x: width - topSize.width, y: height - topSize.height))
            return true
        }
        image.isTemplate = true
        return image
    }
}
