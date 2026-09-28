#!/bin/bash
# 絵を圧縮する。生成された PNG はそのままだと1枚1MB以上あり、リポジトリが重くなる。
#
# 平坦な塗りの絵なので、色数を落とす方式（pngquant）がよく効く。
# 写真と違って階調が少ないため、256色でも見た目はほぼ変わらない。
# 元より大きくなる場合は差し替えない（--skip-if-larger）。
#
#   ./Tools/compress.sh
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v pngquant >/dev/null; then
  echo "pngquant がありません。brew install pngquant で入ります" >&2
  exit 1
fi

before=$(find Resources lp/public -name '*.png' -print0 | xargs -0 stat -f%z | paste -sd+ - | bc)

find Resources lp/public -name '*.png' -print0 |
  xargs -0 pngquant --quality=70-95 --speed 1 --strip --skip-if-larger --force --ext .png

after=$(find Resources lp/public -name '*.png' -print0 | xargs -0 stat -f%z | paste -sd+ - | bc)

printf '%d KB → %d KB（%d%% に）\n' \
  $((before / 1024)) $((after / 1024)) $((after * 100 / before))
