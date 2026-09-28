# 絵の生成に使う指示

ChatGPT に投げる。**Konechi のアイコン（`/Users/piro/Repository/konechi/Resources/konechi-icon.png`）を
参照画像として一緒に添付する。** 文章だけで頼むと絵柄が合わず、姉妹に見えない。

条件の根拠は [SPEC.md](../SPEC.md) の「キャラクター」を参照。メニューバーには出ないので、
Konechi のような 17pt での判別の制約は無い。効くのはドックと Finder の大きさ。

## アプリのアイコン（`Resources/wacchi-icon.png`）

```text
The attached image is the app icon of "Konechi", a small macOS menu bar app.
Draw the app icon for her sister app "Wacchi" in exactly the same art style:
the same chibi proportions, the same face shape and eyes, the same thick dark
outline of uniform weight, the same flat solid fills with no gradients and no
shading, and the same bust-up composition where she holds an object in front
of her.

Wacchi is a different girl, not a recolor of Konechi:

- Hair: bright yellow, gathered into a single side ponytail on her left side
  (the viewer's right). Konechi has two twin tails; Wacchi must have only one.
- A single ahoge on top of her head, shaped like a lightning bolt, in the same
  yellow as her hair.
- A cheerful, energetic smile.

Object: instead of a laptop, she hugs a big white USB-C power adapter (a
rounded square charger brick) with a simple lightning bolt symbol on its front.
A short cable with a USB-C plug comes out of the bottom of the brick.

Canvas: square, 1024x1024. Fill the entire background edge to edge with one
flat solid pale sky blue color. Do not draw rounded corners and do not leave
any transparency — macOS rounds the corners itself. Keep the character and the
charger inside the central 80% so nothing important touches the edges.

Keep it simple: the girl, the charger, and the cable only. No text, no
letters, no numbers, no logos, no background scenery, no drop shadows.
```

## 置き場所と確認

- 受け取った原画は `Resources/wacchi-icon.png` に置く。`build.sh` が `.icns` を組み立てる
- 透過が一画素でも入っていると、macOS 26 は薄い板の上に載せて表示する。
  `sips -g hasAlpha` で `no` を確かめる。入っていたら背景色で塗りつぶした RGB に直す
  （Konechi の `Tools/make-icon.py` と同じ考え方）
- 16px と 32px に縮めて、髪の黄色とアホ毛の稲妻が残っているかを見る

## LP の挿絵（`lp/public/art-*.png`）

アイコンを作ったのと同じチャットの続きで頼む。別のチャットで頼むと顔と髪がずれる。
共通の条件は 1536×1024、背景は本当の透明、文字なし。1枚目の指示で人物の固定を書き、2枚目以降は
「same girl, same style, same canvas rules」で済ませた。

| ファイル | 場面 |
| --- | --- |
| `art-hero.png` | 手を振り、もう片方の手で USB-C のプラグを持つ。プラグの周りに小さな火花 |
| `art-not-zero.png` | 80% の電池を抱えてくつろぐ。電池につながったケーブルに火花が流れ続けている |
| `art-charger.png` | 虫眼鏡で充電器を覗き込む。レンズ越しの片目が大きい |
| `art-no-history.png` | 真っ白なメモ帳を掲げる。耳に鉛筆 |
| `art-quiet.png` | 小さな全身で、黄色い細い帯（メニューバー）に腰かけて手を振る。Konechi の同じ場面と対 |

受け取ったら `./Tools/compress.sh` で色数を落とす。1枚1MB超が 200〜350KB になる。
