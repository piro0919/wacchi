import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { ImageResponse } from "next/og";
import { routing } from "@/i18n/routing";

export const alt = "Wacchi";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

/* ビルド時に焼く。動的なままだと public/ が関数側に含まれず、
   本番で icon.png を読めずに 500 になる */
export function generateStaticParams(): { locale: string }[] {
  return routing.locales.map((locale) => ({ locale }));
}

/* 出るのは kk-web の一覧で176px、X のカードで500px 前後。
   その大きさで残るのはアイコンと名前と1行だけ。色はアイコンから取る */
const YELLOW = "#fde356";
const INK = "#241010";

export default async function OgImage({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<ImageResponse> {
  const { locale } = await params;
  const isJa = locale === "ja";
  /* 見出しの書体はサイトと同じ Mochiy Pop One。使う文字だけに絞ったものを
     同梱している。文言を変えたら assets/README.md の手順で作り直す */
  const [icon, font] = await Promise.all([
    readFile(join(process.cwd(), "public/icon.png")),
    readFile(join(process.cwd(), "assets/MochiyPopOne-subset.ttf")),
  ]);
  const iconSrc = `data:image/png;base64,${icon.toString("base64")}`;

  return new ImageResponse(
    <div
      style={{
        alignItems: "center",
        /* 地をアイコンと同じ空色にすると、アイコンの輪郭が溶けて消える。
           髪の黄色を地にして、アイコンはアプリと同じ太い焦げ茶の枠で囲う */
        background: YELLOW,
        display: "flex",
        gap: 56,
        height: "100%",
        justifyContent: "center",
        width: "100%",
      }}
    >
      <div
        style={{
          border: `8px solid ${INK}`,
          borderRadius: 64,
          boxShadow: `0 14px 0 0 ${INK}`,
          display: "flex",
          overflow: "hidden",
        }}
      >
        {/* biome-ignore lint/performance/noImgElement: next/image is not available in ImageResponse */}
        <img alt="" height={260} src={iconSrc} width={260} />
      </div>
      <div style={{ display: "flex", flexDirection: "column" }}>
        <div style={{ color: INK, fontSize: 120 }}>Wacchi</div>
        <div style={{ color: INK, display: "flex", fontSize: 40, marginTop: 10 }}>
          {isJa ? "充電器から、いま何ワット？" : "How many watts from your charger?"}
        </div>
      </div>
    </div>,
    {
      ...size,
      fonts: [{ data: font, name: "Mochiy Pop One", style: "normal", weight: 400 }],
    },
  );
}
