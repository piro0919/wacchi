# assets

`MochiyPopOne-subset.ttf` is the face drawn into the Open Graph card
(`src/app/[locale]/opengraph-image.tsx`). It is the same display face the site
uses for its headings, cut down to the characters the card actually shows.

Any character missing from it silently falls back to a different face, so when
the card's copy changes, rebuild the subset:

```sh
curl -sL -o /tmp/MochiyPopOne-Regular.ttf \
  "https://github.com/google/fonts/raw/main/ofl/mochiypopone/MochiyPopOne-Regular.ttf"

pyftsubset /tmp/MochiyPopOne-Regular.ttf \
  --text="Wacchi How many watts from your charger? 充電器から、いま何ワット？" \
  --unicodes="U+0020-007E" \
  --output-file=assets/MochiyPopOne-subset.ttf \
  --no-hinting --desubroutinize --layout-features=''
```
