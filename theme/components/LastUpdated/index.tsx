import { useI18n, usePageData } from '@rspress/core/runtime';

/**
 * Custom LastUpdated component that always renders if lastUpdatedTime is set.
 * Unlike Rspress built-in, this doesn't depend on themeConfig.lastUpdated
 * (which we disable to prevent the built-in git-log overriding our plugin value).
 */
export function LastUpdated() {
  const { page } = usePageData();
  const t = useI18n();
  const { lastUpdatedTime } = page;

  if (!lastUpdatedTime) return null;

  return (
    <div className="rp-last-updated">
      <p>
        {t('lastUpdatedText')}: <span>{lastUpdatedTime}</span>
      </p>
    </div>
  );
}
