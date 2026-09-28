"use client";

import { useLocale, useTranslations } from "next-intl";
import { Link, usePathname } from "@/i18n/navigation";

/// 言語の切り替え。既定が英語なので、日本語話者が辿り着ける入口が要る
export function LanguageSwitch() {
  const locale = useLocale();
  const t = useTranslations("language");
  const pathname = usePathname();

  return (
    <div className="flex items-center gap-1 rounded-full border-2 border-[var(--color-ink)] bg-white p-1 text-sm">
      {(["en", "ja"] as const).map((target) => (
        <Link
          className={`rounded-full px-3 py-1 font-bold transition ${
            locale === target
              ? "bg-[var(--color-ink)] text-white"
              : "text-[var(--color-ink)]/70 hover:text-[var(--color-ink)]"
          }`}
          href={pathname}
          key={target}
          locale={target}
        >
          {t(target)}
        </Link>
      ))}
    </div>
  );
}
