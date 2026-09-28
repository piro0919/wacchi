# Wacchi

A tiny macOS menu bar app that shows how much power your Mac is drawing from
its charger, stacked above the most the charger can give it — `11W` on top,
`94W` underneath. With no charger connected it shows a single `0W`.

Wacchi reads the same registry entry `ioreg -rn AppleSmartBattery` prints:

- **Drawing** is `PowerTelemetryData.SystemPowerIn` — what the whole Mac pulls
  from the charger right now. It is not the power flowing into the battery, so
  it does not drop to 0W while macOS holds the battery at its charge limit
- **Max** is `AdapterDetails.Watts` — the wattage the charger and the Mac
  agreed on

It keeps no history and draws no charts. Only the current reading is read, every
two seconds, and nothing is written to disk.

## Install

```bash
brew install --cask piro0919/tap/wacchi
```

Or download the DMG from [Releases](https://github.com/piro0919/wacchi/releases/latest).
Apple Silicon, macOS 14 or later.

## Build

Xcode is not required — the Swift that ships with the Command Line Tools is
enough. Sparkle, used for updates, is fetched into `Vendor/` on the first
build.

```bash
./build.sh
open Wacchi.app
```

## What the menu shows

| Row     | Contents                                                                        |
| ------- | ------------------------------------------------------------------------------- |
| Status  | Charging / Held at the charge limit / Fully charged / Not charging / On battery |
| Battery | The charge level                                                                |
| Charger | The adapter's name (e.g. 96W USB-C Power Adapter)                               |
| Max     | The negotiated wattage                                                          |
| Drawing | The power coming in from the charger, to one decimal place                      |

The charge limit is read from macOS's own setting in System Settings → Battery.
Comparing the rating in the charger's name with the negotiated wattage tells you
whether the charger is giving all it can.

## Settings

Launch at login, language (Japanese / English), which rows appear in the menu,
checking for updates, and the version.

The language defaults to English, and only falls back to Japanese when the
system is set to Japanese.

## Development

The app itself takes flags for inspecting what it reads.

```bash
./Wacchi.app/Contents/MacOS/Wacchi --selftest   # formatting, state and charge-limit parsing
./Wacchi.app/Contents/MacOS/Wacchi --probe      # print the raw readings and the resulting title
./Wacchi.app/Contents/MacOS/Wacchi --settings   # open with the settings window
```

## Landing page

`lp/` holds the site published at <https://wacchi.kkweb.io> — Next.js with
next-intl, Japanese and English. It lives in this repository so a release and
the wording that describes it land in the same commit.

```bash
pnpm install
pnpm lp:dev
```

## Design decisions

See [SPEC.md](./SPEC.md), which also records the approaches that were dropped,
and why.

## Notes

- Macs without a battery have no `AppleSmartBattery` entry, so Wacchi shows 0W
- If you use a menu bar manager such as Ice, a newly added item starts out in
  the hidden section
- Builds are ad-hoc signed. The first launch is met with an "unidentified
  developer" warning; allow it from System Settings

> 仕様の記録（[SPEC.md](./SPEC.md)）は日本語です。

## License

MIT
