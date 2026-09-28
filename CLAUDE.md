# CLAUDE.md (Wacchi)

How to work in this repository. The behaviour itself is documented elsewhere — do not
restate it here.

## Where the truth lives

- **[SPEC.md](SPEC.md)** — what was decided and why. Open questions stay under 保留.
  Change the text here before changing the implementation, not after
- **[README.md](README.md)** — the outward description: what the app does, how to build it,
  what the menu shows
- **[build.sh](build.sh) / [release.sh](release.sh)** — the comments inside the scripts are the
  procedure. Do not write a second copy of it in prose

The layout follows Konechi (`/Users/piro/Repository/konechi`). When something here is missing,
look there first.

## Language

Commit messages, PR titles and bodies, the README, docs, and release notes are written in
English. This file is part of that.

**Comments in the source, SPEC.md, and the explanations inside the shell scripts stay in
Japanese.** That is what the existing code does. Do not translate them.

## Building

Xcode is not needed. The `swiftc` that ships with the Command Line Tools is enough.

```bash
./build.sh          # produces Wacchi.app; fetches Sparkle into Vendor/ if missing
open Wacchi.app
```

- `Vendor/` is not tracked. If it disappears, `build.sh` fetches it again
- The version is passed in through `WACCHI_VERSION`. Local builds stay at `0.0.0`
- A new source file must also be added to the file list in `build.sh`
- The landing page is a pnpm workspace under `lp/`, modelled on Hawky's. Use `pnpm lp:dev` and
  `pnpm lp:build`. CI runs its lint, typecheck and build on Linux

## Gather what you can before asking

- `./Wacchi.app/Contents/MacOS/Wacchi --probe` — prints the raw readings and the title built
  from them
- `ioreg -rn AppleSmartBattery` — the registry entry every value comes from
- The charge limit lives in `/Library/Preferences/com.apple.powerd.charging.plist`; `policies`
  is an NSKeyedArchiver blob, readable with `plutil -extract policies raw -o - … | base64 -d`

The menu bar item starts in Ice's hidden section, at x ≈ -9000. Its title and menu rows can
still be read through System Events (`menu bar 1` of process "Wacchi"), but a screenshot needs
the item moved into the visible section first.

## Keep it light

Wacchi exists because WattsConnected grew to 1.6 GB by rewriting its whole history into
UserDefaults every minute. Do not add history, charts, or anything written on a timer.
Read only the keys a refresh needs with `IORegistryEntryCreateCFProperty`.

## Releasing

`./release.sh <version>` builds, makes the DMG, signs the update feed, and pushes to GitHub
Releases in one pass.

- **The signing key lives in the login keychain and is shared with Konechi, Nonja, Okigae and
  Gocci. Lose it and already-installed copies can never be updated again**
- `generate_appcast` stops when it sees two archives of the same version. Keep the zip and the
  DMG in separate directories
