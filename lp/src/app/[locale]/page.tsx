import Image from "next/image";
import { getTranslations, setRequestLocale } from "next-intl/server";
import type { ReactNode } from "react";
import { Link } from "@/i18n/navigation";
import { LanguageSwitch } from "./language-switch";

const REPO = "https://github.com/piro0919/wacchi";
const DOWNLOAD = `${REPO}/releases/latest`;
const BREW = "brew install --cask piro0919/tap/wacchi";

type Step = { title: string; body: string };

type PageProps = {
  params: Promise<{ locale: string }>;
};

function DownloadButton({ children }: { children: ReactNode }) {
  return (
    <a
      className="sticker inline-block rounded-full bg-[var(--color-yellow)] px-9 py-4 font-black text-[var(--color-ink)] transition active:translate-y-1 active:shadow-[0_2px_0_0_var(--color-ink)]"
      href={DOWNLOAD}
    >
      {children}
    </a>
  );
}

/// ターミナルに貼る1行。横に長いので、狭い画面では中で横に流す
function Command({ children }: { children: string }) {
  return (
    <pre className="overflow-x-auto rounded-2xl bg-[var(--color-ink)] px-5 py-4 text-left font-mono text-[13px] text-white/90 leading-relaxed">
      <code>{children}</code>
    </pre>
  );
}

export default async function Page({ params }: PageProps) {
  const { locale } = await params;
  setRequestLocale(locale);

  const t = await getTranslations();
  const install = t.raw("install.steps") as Step[];
  const features = ["not_zero", "charger", "no_history", "quiet"] as const;
  const shot = locale === "ja" ? "/shot-menu-ja.png" : "/shot-menu-en.png";

  return (
    <>
      {/* 見出し。地をアイコンと同じ空色にして、絵の四角い縁を溶かしている */}
      <section className="sky relative overflow-hidden px-6 pt-16 pb-10">
        <div className="relative mx-auto flex max-w-5xl flex-col items-center gap-10 lg:flex-row">
          <div className="flex flex-1 flex-col items-center gap-6 text-center lg:items-start lg:text-left">
            <div className="flex items-center gap-3">
              <span className="rounded-full border-2 border-[var(--color-ink)] bg-white px-4 py-1 font-bold text-sm">
                macOS
              </span>
              <LanguageSwitch />
            </div>
            <div className="flex items-center gap-4">
              <Image
                alt=""
                className="h-16 w-16 rounded-[18px]"
                height={128}
                priority
                src="/icon.png"
                width={128}
              />
              <span className="display text-4xl">Wacchi</span>
            </div>
            <h1 className="display text-balance text-4xl leading-[1.35] sm:text-5xl">
              {t("hero.tagline")}
            </h1>
            <p className="max-w-md text-lg leading-relaxed">{t("hero.lead")}</p>
            <div className="flex flex-col items-center gap-3 lg:items-start">
              <DownloadButton>{t("hero.download")}</DownloadButton>
              <p className="text-sm opacity-70">{t("hero.requirement")}</p>
            </div>
          </div>

          <div className="flex flex-1 justify-center">
            <Image
              alt=""
              className="w-full max-w-md"
              height={800}
              priority
              src="/wacchi.png"
              width={800}
            />
          </div>
        </div>
      </section>

      <div className="bolts bg-[var(--color-cream)]" />

      {/* 数字の読み方 */}
      <section className="px-6 py-16">
        <div className="mx-auto flex max-w-5xl flex-col items-center gap-12 lg:flex-row">
          <div className="flex flex-1 justify-center">
            <Image
              alt=""
              className="sticker w-full max-w-md rounded-3xl"
              height={600}
              src={shot}
              width={820}
            />
          </div>
          <div className="flex flex-1 flex-col gap-6">
            <h2 className="display text-center text-3xl lg:text-left">{t("reading.title")}</h2>
            {(["top", "bottom"] as const).map((key) => (
              <div className="flex gap-4 rounded-[28px] bg-white p-6 shadow-sm" key={key}>
                <span
                  className={`display flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl border-[3px] border-[var(--color-ink)] text-lg ${
                    key === "top" ? "bg-[var(--color-yellow)]" : "bg-[var(--color-sky)]"
                  }`}
                >
                  {key === "top" ? "12W" : "94W"}
                </span>
                <div className="flex flex-col gap-1">
                  <h3 className="font-black text-lg">{t(`reading.${key}.label`)}</h3>
                  <p className="leading-relaxed opacity-75">{t(`reading.${key}.body`)}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* できること */}
      <section className="bg-[var(--color-yellow)] px-6 py-20">
        <div className="mx-auto flex max-w-5xl flex-col gap-12">
          <h2 className="display text-center text-3xl">{t("features.title")}</h2>
          <div className="grid gap-8 sm:grid-cols-2">
            {features.map((key) => (
              <div className="sticker flex flex-col gap-3 rounded-[28px] bg-white p-8" key={key}>
                <h3 className="font-black text-xl">{t(`features.${key}.title`)}</h3>
                <p className="leading-relaxed opacity-75">{t(`features.${key}.body`)}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 入れ方 */}
      <section className="sky px-6 py-20">
        <div className="mx-auto flex max-w-3xl flex-col gap-10">
          <h2 className="display text-center text-3xl">{t("install.title")}</h2>
          <ol className="flex flex-col gap-8">
            {install.map((step, index) => (
              <li className="flex gap-5" key={step.title}>
                <span className="display flex h-11 w-11 shrink-0 items-center justify-center rounded-full border-[3px] border-[var(--color-ink)] bg-[var(--color-yellow)] text-lg">
                  {index + 1}
                </span>
                <div className="flex min-w-0 flex-1 flex-col gap-3">
                  <h3 className="font-black text-lg">{step.title}</h3>
                  <p className="leading-relaxed">{step.body}</p>
                  {index === 0 && <Command>{BREW}</Command>}
                </div>
              </li>
            ))}
          </ol>
          <p className="text-center text-sm leading-relaxed opacity-75">{t("install.note")}</p>
          <div className="flex justify-center">
            <DownloadButton>{t("install.cta")}</DownloadButton>
          </div>
        </div>
      </section>

      <footer className="flex justify-center gap-6 bg-[var(--color-cream)] px-6 py-10 text-sm">
        <a className="font-bold opacity-60 hover:opacity-100" href={REPO}>
          {t("footer.source")}
        </a>
        <a className="font-bold opacity-60 hover:opacity-100" href={`${REPO}/releases`}>
          {t("footer.releases")}
        </a>
        <Link className="font-bold opacity-60 hover:opacity-100" href="/privacy">
          {t("footer.privacy")}
        </Link>
      </footer>
    </>
  );
}
