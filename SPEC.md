# 仕様

壁打ちで決まったことを置く場所。決まっていないものは「保留」に残す。

## なぜ作るか

WattsConnected の置き換え。2026-09-29 に手元で見たところ、3日起動したままで物理メモリが 1.6GB あり、
RSS は20秒ごとに約2MB ずつ増え続けていた。CPU は保存のたびに跳ねていて、サンプリングすると
アプリ自身の時間のほぼ全部が `PropertyListEncoder.encode` だった。1分ごとの電力の記録
（`batteryPowerMinuteSamples`、284KB）を UserDefaults に溜め、1件足すたびに全件を書き直している。

軽さだけでは差にならない。「軽量」は Charger Wattage が既に名乗っている。差は次の2つに置く。

- **無料で、更新が続いていること。** 有料の Charger Wattage も無料の WhatWatt も 2025年9月で止まっている
- **充電の上限を使っていても、今の値が 0W にならないこと。** 下の「表示するもの」を参照

## 決まったこと

### 名前

**Wacchi（わっち）。** ワット由来。Konechi と同じく「〇〇ち」の形で、アプリ名とキャラ名を同じにする。

- 同名の Mac・iOS アプリは見つからなかった。Homebrew にも同名の Cask は無い
- `github.com/piro0919/wacchi` と `wacchi.kkweb.io` はどちらも空いていることを確認済み。
  他人の `kiyohome/wacchi` はあるが、2021年から止まっていて中身は見出し1行だけ
- 「わっち」は廓言葉や方言の一人称でもある。女の子のキャラの名前としては味になる
- 見送った候補: Pawachi、Mogucchi、Genkichi、Kyuchi、Denchi ほか。Denchi は普通名詞と同じで検索に埋もれる

### 表示するもの

**メニューバーには数字だけを出す。** 上に充電器から引いている電力、下に取り決めた上限の2段。例: 上 `11W`、下 `94W`。
顔は出さない。Konechi はアイコンだけだが、Wacchi は開かずに数字が見えることが役目なので逆になる。

- 最初は1行の `11 / 94W` で組んだが、2段に変えた。1行だと幅が 64pt あり、2段なら半分ほどで済む
- 上は太字、下は細字で薄くして、どちらが今の値かを見分けられるようにする
- 文字ではなく絵として描き、テンプレート画像にする。メニューバーの明暗に合わせて色が変わる。
  描き直しは値が変わったときだけ

- **上限**は充電器と Mac が取り決めた値。`AppleSmartBattery` の `AdapterDetails.Watts`
- **今の値**は充電器から Mac 全体に入っている電力。`PowerTelemetryData.SystemPowerIn`（mW）。
  `SystemVoltageIn` × `SystemCurrentIn` と一致することを確かめてある（20.326V × 0.580A = 11.8W）
- **バッテリーに出入りする電力は使わない。** WattsConnected の今の値はこちらで、充電の上限で止まっている間は
  「Idle / No power flow」、つまり 0W になる。そのとき Mac は充電器から約 11W 引いている。
  上限を設定して使う人にとって意味があるのは、充電器から引いている側
- 充電器が挿さっていないときは、2段にせず1段で `0W` と出す（仮決め）

ドロップダウンには次の行を出す。どの行を出すかは設定で選べる。状態の行だけは隠せない。

| 行 | 中身 | 出どころ |
| --- | --- | --- |
| 状態 | 充電中 / 上限 80% で停止中 / 満充電 / 充電していない / バッテリー駆動 | `ExternalConnected`、`IsCharging`、`FullyCharged`、充電の上限 |
| 残量 | 80% | `CurrentCapacity` |
| 充電器 | 96W USB-C Power Adapter | `AdapterDetails.Name`。無ければ `Manufacturer` |
| 最大 | 94W | `AdapterDetails.Watts` |
| 今の電力 | 11.8W | `PowerTelemetryData.SystemPowerIn` |

定格（名前の 96W）と取り決めた上限（94W）を並べると、充電器の力を出し切れているかが分かる。

### 充電の上限の読み方

macOS 本体の「充電上限」は `/Library/Preferences/com.apple.powerd.charging.plist` にある。
`policies` が NSKeyedArchiver で固めたデータで、中の `ChargeCtrlPolicy` に `soclimit`（例: 80）と
`reason`（`manualChargeLimit`）が入っている。一般ユーザーの権限で読める。

`ChargeCtrlPolicy` のクラスはこちらに無いので、解凍はせず plist として開き、`$objects` の中から
`soclimit` を持ち `terminated` が偽の辞書を探す。

### 入れないもの

- **履歴とグラフ。** WattsConnected の重さの原因そのもの。今の表示に要るのは上限と今の値の2つだけ
- ケーブルが足を引っ張っているかの判定、バッテリーの劣化具合。後回し

### 更新の間隔

今の値だけ2秒ごとに読む。`IORegistryEntryCreateCFProperty` で要る鍵だけ取り、`BatteryData` のような
大きい辞書を丸ごと写さない。状態・充電器・上限は、電源の抜き挿しの通知とメニューを開いたときに読み直す。
保険として10秒ごとにも読む。

### 設定

Konechi にそろえる。ログイン時の起動、言語（日本語 / 英語）、ドロップダウンに出す行、更新の確認、版。
アイコンの切り替えは無い。メニューバーに絵を出さないため。

### 配り方

無料・MIT。GitHub Releases に DMG を置き、Sparkle で更新を届け、Homebrew Cask でも入れられるようにする。
Cask は `piro0919/homebrew-tap` の `Casks/wacchi.rb`。リリースのたびに version と sha256 を直す。
Sparkle の署名鍵は Konechi・Nonja・Okigae・Gocci と同じものを使う。

### キャラクター

- Konechi と同じ絵柄のちびキャラ。姉妹として並べる
- **髪は黄色。** 電気の色で、Konechi のピンクと並べて別の子に見える
- **髪型はサイドテールに、稲妻形のアホ毛を1本。** Konechi の太く短いツインテールと輪郭で見分けがつき、
  アホ毛だけで電気のキャラだと分かる
- 出番はアプリのアイコンと LP。メニューバーには出ないので、22pt で読める必要は無い

## 保留

- 充電器が無いときの表示（今は `0W`）
- `ChargerData.NotChargingReason` の値の意味。分かれば「充電していない」の理由を出せる
- LP（`wacchi.kkweb.io`）
