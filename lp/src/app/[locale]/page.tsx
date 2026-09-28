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

/// 帯と帯の境目に置く波。直線で切るより柔らかくなる
function Wave({ color, flip = false }: { color: string; flip?: boolean }) {
  return (
    <svg
      aria-hidden="true"
      className={`block h-12 w-full ${flip ? "rotate-180" : ""}`}
      preserveAspectRatio="none"
      viewBox="0 0 1440 48"
    >
      <path
        d="M0 24c120 18 240 24 360 18s240-30 360-30 240 24 360 30 240 0 360-18v48H0z"
        fill={color}
      />
    </svg>
  );
}

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
  const shot = locale === "ja" ? "/shot-menu-ja.png" : "/shot-menu-en.png";

  const features = [
    { art: "/art-not-zero.png", key: "not_zero" },
    { art: "/art-charger.png", key: "charger" },
    { art: "/art-no-history.png", key: "no_history" },
    { art: "/art-quiet.png", key: "quiet" },
  ] as const;

  return (
    <>
      {/* 見出し */}
      <section className="dots relative overflow-hidden px-6 pt-20 pb-24">
        <div
          className="blob -top-20 -left-20 h-80 w-80"
          style={{ background: "var(--color-yellow)" }}
        />
        <div
          className="blob top-40 -right-24 h-96 w-96"
          style={{ background: "var(--color-sky)" }}
        />
        <div className="relative mx-auto flex max-w-5xl flex-col items-center gap-16 lg:flex-row lg:gap-12">
          <div className="flex flex-1 flex-col items-center gap-6 text-center lg:items-start lg:text-left">
            <div className="flex items-center gap-3">
              <span className="rounded-full border-2 border-[var(--color-ink)] bg-white px-4 py-1 font-bold text-sm">
                macOS
              </span>
              <LanguageSwitch />
            </div>
            <div className="flex items-center gap-3">
              <Image
                alt=""
                className="h-12 w-12 rounded-[14px]"
                height={96}
                priority
                src="/icon.png"
                width={96}
              />
              <span className="display text-3xl">Wacchi</span>
            </div>
            <h1 className="display text-balance text-4xl leading-[1.4] sm:text-5xl">
              <span className="marker">{t("hero.tagline")}</span>
            </h1>
            <p className="max-w-md text-lg leading-relaxed opacity-80">{t("hero.lead")}</p>
            <div className="flex flex-col items-center gap-3 lg:items-start">
              <DownloadButton>{t("hero.download")}</DownloadButton>
              <p className="text-sm opacity-60">{t("hero.requirement")}</p>
            </div>
          </div>

          <div className="relative flex flex-1 justify-center">
            <Image
              alt=""
              className="w-full max-w-md rotate-2 rounded-3xl shadow-[0_24px_60px_-12px_rgba(36,16,16,0.4)]"
              height={600}
              priority
              src={shot}
              width={820}
            />
            <Image
              alt=""
              className="-bottom-20 -left-14 absolute w-60 drop-shadow-xl sm:w-80"
              height={1024}
              priority
              src="/art-hero.png"
              width={1536}
            />
          </div>
        </div>
      </section>

      <Wave color="#ffffff" />

      {/* 数字の読み方 */}
      <section className="bg-white px-6 pb-20">
        <div className="mx-auto flex max-w-5xl flex-col items-center gap-10">
          <h2 className="display text-center text-3xl">
            <span className="marker">{t("reading.title")}</span>
          </h2>
          <div className="grid w-full items-center gap-6 sm:grid-cols-[1fr_auto_1fr]">
            {(["top", "bottom"] as const).map((key, index) => (
              <div
                className={`flex flex-col gap-2 rounded-[32px] border-4 border-[var(--color-cream-deep)] bg-[var(--color-cream)] p-7 shadow-sm transition hover:-translate-y-1 hover:rotate-0 ${
                  index === 0 ? "sm:order-1 sm:-rotate-2" : "sm:order-3 sm:rotate-2"
                }`}
                key={key}
              >
                <span
                  className={`self-start rounded-full px-4 py-1 font-bold text-sm ${
                    key === "top"
                      ? "bg-[var(--color-yellow)]"
                      : "bg-[var(--color-sky)] text-[var(--color-ink)]"
                  }`}
                >
                  {t(`reading.${key}.label`)}
                </span>
                <p className="leading-relaxed opacity-80">{t(`reading.${key}.body`)}</p>
              </div>
            ))}
            <Image
              alt=""
              className="order-first mx-auto w-40 sm:order-2 sm:w-44"
              height={232}
              src="/title-big.png"
              width={304}
            />
          </div>
        </div>
      </section>

      <Wave color="var(--color-cream)" />

      {/* できること */}
      <section className="dots relative overflow-hidden px-6 pb-24">
        <div
          className="blob top-1/3 -left-32 h-96 w-96"
          style={{ background: "var(--color-sky)" }}
        />
        <div
          className="blob bottom-10 -right-32 h-96 w-96"
          style={{ background: "var(--color-yellow)" }}
        />
        <div className="relative mx-auto flex max-w-5xl flex-col gap-12">
          <h2 className="display text-center text-3xl">
            <span className="marker">{t("features.title")}</span>
          </h2>
          {features.map(({ art, key }, index) => (
            <div
              className={`flex flex-col items-center gap-6 rounded-[32px] border-4 border-white bg-white/75 p-8 sm:gap-12 sm:p-10 ${
                index % 2 === 0 ? "sm:flex-row" : "sm:flex-row-reverse"
              }`}
              key={key}
            >
              <div className="flex flex-1 justify-center">
                <Image
                  alt=""
                  className="w-full max-w-[360px] drop-shadow-lg"
                  height={1024}
                  src={art}
                  width={1536}
                />
              </div>
              <div className="flex flex-[1.2] flex-col gap-3 text-center sm:text-left">
                <h3 className="font-black text-xl">{t(`features.${key}.title`)}</h3>
                <p className="leading-relaxed opacity-80">{t(`features.${key}.body`)}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 入れ方 */}
      <section className="relative overflow-hidden bg-[var(--color-yellow)] px-6 py-20">
        <div
          className="blob -top-24 right-10 h-72 w-72"
          style={{ background: "#ffffff", opacity: 0.5 }}
        />
        <div className="relative mx-auto flex max-w-3xl flex-col items-center gap-10">
          <Image
            alt=""
            className="sticker w-full max-w-xs rounded-[40px]"
            height={800}
            src="/wacchi.png"
            width={800}
          />
          <h2 className="display text-center text-3xl">{t("install.title")}</h2>
          <ol className="flex w-full flex-col gap-8">
            {install.map((step, index) => (
              <li className="flex gap-5" key={step.title}>
                <span className="display flex h-11 w-11 shrink-0 items-center justify-center rounded-full border-[3px] border-[var(--color-ink)] bg-white text-lg">
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
          <a
            className="inline-block rounded-full bg-[var(--color-ink)] px-9 py-4 font-black text-white shadow-[0_8px_0_0_rgba(36,16,16,0.25)] transition active:translate-y-1 active:shadow-[0_3px_0_0_rgba(36,16,16,0.25)]"
            href={DOWNLOAD}
          >
            {t("install.cta")}
          </a>
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
