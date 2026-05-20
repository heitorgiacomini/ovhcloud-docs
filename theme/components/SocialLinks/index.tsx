import { useSite } from '@rspress/core/runtime';
import virtual_social_links from 'virtual-social-links';

/**
 * Accessible replacement for the Rspress core SocialLinks component.
 * Adds `aria-label` to each <a> so screen readers can announce the link target
 * (Rspress core renders icon-only <a> without any discernible name).
 */
export function SocialLinks() {
  const { site } = useSite();
  const socialLinks = site.themeConfig?.socialLinks ?? [];

  if (socialLinks.length === 0) return null;

  return (
    <div className="rp-social-links">
      {socialLinks.map((link) => {
        const { icon, mode = 'link', content } = link;
        const iconHtml =
          typeof icon === 'string'
            ? (virtual_social_links as Record<string, string>)[icon]
            : icon?.svg;
        // Derive an accessible name: use the icon id when present (e.g. "github"),
        // otherwise fall back to the target URL/text.
        const label =
          typeof icon === 'string'
            ? `${icon.charAt(0).toUpperCase()}${icon.slice(1)}`
            : (content ?? 'Link');

        if (mode !== 'link') {
          return null;
        }

        return (
          <a
            key={content}
            href={content}
            target="_blank"
            rel="noopener noreferrer"
            className="rp-social-links__item"
            aria-label={label}
          >
            <div
              className="rp-social-links__icon"
              // biome-ignore lint/security/noDangerouslySetInnerHtml: SVG content comes from the trusted virtual-social-links module
              dangerouslySetInnerHTML={{ __html: iconHtml ?? '' }}
            />
          </a>
        );
      })}
    </div>
  );
}
