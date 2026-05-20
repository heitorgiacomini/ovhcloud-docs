import { Head, useLang, useLocation } from '@rspress/core/runtime';

const SITE_URL = 'https://docs.ovhcloud.com';
const LOCALES = ['fr', 'en', 'de', 'es', 'it', 'pl', 'pt'] as const;
const LOCALES_SET = new Set<string>(LOCALES);
const DEFAULT_LOCALE = 'en'; // used for hreflang="x-default"

/**
 * Injects <link rel="canonical"> and <link rel="alternate" hreflang="..." />
 * tags in <head> of every page (SSG + SPA navigations).
 *
 * Uses the <Head> component from @rspress/core/runtime (powered internally by
 * @unhead/react) which works in both SSG output and SPA navigations.
 *
 * Locale handling:
 * - In prod, pathname always starts with /{locale}/.
 * - In dev, the default locale's pathname has NO prefix (e.g. /guides/foo)
 *   while non-default locales do (e.g. /en/guides/foo).
 * - We rely on useLang() (always returns the active locale) and strip the
 *   locale prefix from pathname if present.
 *
 * Assumes each documentation page exists in all 7 locales — true 99%+ of the
 * time thanks to the symlink fallback strategy in docs/{locale}/guides/.
 */
export function SEOHead() {
  const lang = useLang();
  const { pathname } = useLocation();

  // Strip locale prefix from pathname if present
  const m = pathname.match(/^\/([a-z]{2})(\/.*)?$/);
  const pathHasLocalePrefix = m && LOCALES_SET.has(m[1]);
  const relPath = pathHasLocalePrefix ? (m[2] ?? '/') : pathname;
  // Strip trailing slash except for root
  const cleanRel = relPath === '/' ? '/' : relPath.replace(/\/$/, '');

  const currentLocale = LOCALES_SET.has(lang) ? lang : DEFAULT_LOCALE;

  const localeUrl = (locale: string) =>
    `${SITE_URL}/${locale}${cleanRel === '/' ? '/' : cleanRel}`;

  return (
    <Head>
      <link rel="canonical" href={localeUrl(currentLocale)} />
      {LOCALES.map((l) => (
        <link key={l} rel="alternate" hrefLang={l} href={localeUrl(l)} />
      ))}
      <link
        rel="alternate"
        hrefLang="x-default"
        href={localeUrl(DEFAULT_LOCALE)}
      />
    </Head>
  );
}
