import {
  addLeadingSlash,
  normalizeImagePath,
  useLocaleSiteData,
  useSite,
} from '@rspress/core/runtime';
import { Link } from '@theme-original';
import { useMemo } from 'react';
import './NavTitle.scss';

export const NavTitle = () => {
  const { site } = useSite();
  const localeData = useLocaleSiteData();
  const { logo: rawLogo, logoText } = site;
  const title = (localeData.title ?? site.title) || 'Home';
  const logo = useMemo(() => {
    if (!rawLogo) {
      return null;
    }
    // Intrinsic dimensions from SVG viewBox (298x47) — CSS overrides the
    // rendered size via .rspress-logo { height: 1.6rem }. Providing explicit
    // width/height lets the browser reserve space and avoid CLS.
    if (typeof rawLogo === 'string') {
      return (
        <img
          src={normalizeImagePath(rawLogo)}
          alt="logo"
          id="logo"
          width={298}
          height={47}
          className="rspress-logo rp-nav__title__logo-image"
        />
      );
    }
    return (
      <>
        <img
          src={normalizeImagePath(rawLogo.light)}
          alt="logo"
          id="logo"
          width={298}
          height={47}
          className="rspress-logo rp-nav__title__logo-image rp-nav__title__logo-image--light"
        />
        <img
          src={normalizeImagePath(rawLogo.dark)}
          alt="logo"
          id="logo"
          width={298}
          height={47}
          className="rspress-logo rp-nav__title__logo-image rp-nav__title__logo-image--dark"
        />
      </>
    );
  }, [rawLogo]);

  return (
    <div className="rp-nav__title">
      <Link
        href={addLeadingSlash(
          (localeData as typeof localeData & { langRoutePrefix?: string })
            .langRoutePrefix ?? '/',
        )}
        className="rp-nav__title__link"
      >
        {logo && <div className="rp-nav__title__logo">{logo}</div>}
        {logoText && <span>{logoText}</span>}
        {!logo && !logoText && <span>{title}</span>}
      </Link>
    </div>
  );
};
