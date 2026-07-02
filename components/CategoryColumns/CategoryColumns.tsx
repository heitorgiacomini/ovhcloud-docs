import { useLocalizeHref } from '../../theme/hooks/useLocalizedHref';
import { useZone, type Zone } from '../Zone/ZoneContext';
import './CategoryColumns.css';

interface CategoryItem {
  title: string;
  link?: string;
  /**
   * Commercial zones this item is available in. Omit to show everywhere.
   * An item whose zones exclude the active zone is filtered out (no link,
   * no placeholder) — same semantics as the <Region> component.
   */
  zones?: Zone[];
}

interface Category {
  title: string;
  items: CategoryItem[];
}

interface CategoryColumnsProps {
  /**
   * Categories to display. Each becomes a column; columns flow two per row
   * and collapse to a single column on narrow screens.
   */
  categories: Category[];
}

const isExternal = (href: string) =>
  href.startsWith('http://') || href.startsWith('https://');

/**
 * Condensed two-column directory of guide links grouped by category.
 *
 * Categories flow row by row (1 2 / 3 4 …); within a category the guide
 * titles stack as a light vertical list. The only separator is a thin rule
 * under each category heading — no per-item dividers — to keep it uncluttered.
 */
export function CategoryColumns({ categories }: CategoryColumnsProps) {
  const localizeHref = useLocalizeHref();
  const { effectiveZone } = useZone();

  // Filter items by active zone, then drop categories left with no items.
  const visibleCategories = (categories ?? [])
    .map((cat) => ({
      ...cat,
      items: cat.items.filter(
        (item) => !item.zones || item.zones.includes(effectiveZone),
      ),
    }))
    .filter((cat) => cat.items.length > 0);

  if (visibleCategories.length === 0) {
    return null;
  }

  // Deal the sections, in source order, each onto the currently shorter column
  // (ties to the left). This keeps the two columns as close in height as
  // possible whatever the section sizes — a lone big section pairs with several
  // small ones instead of piling up on one side. Each section keeps its source
  // index as `order`, so the single-column mobile stack still reads in order.
  const weight = (cat: Category) => cat.items.length + 2;
  const columns: { cat: Category; order: number }[][] = [[], []];
  const heights = [0, 0];
  visibleCategories.forEach((cat, i) => {
    const col = heights[0] <= heights[1] ? 0 : 1;
    columns[col].push({ cat, order: i });
    heights[col] += weight(cat);
  });

  return (
    <div className="rp-category-columns">
      {columns.map((column, colIndex) => (
        <div className="rp-category-columns__group" key={colIndex}>
          {column.map(({ cat, order }) => (
            <section
              className="rp-category-columns__col"
              style={{ order }}
              key={cat.title}
            >
              {cat.title ? (
                <h3 className="rp-category-columns__heading">{cat.title}</h3>
              ) : (
                <div
                  className="rp-category-columns__heading rp-category-columns__heading--spacer"
                  aria-hidden="true"
                />
              )}
              <ul className="rp-category-columns__list">
                {cat.items.map((item) => (
                  <li key={item.title}>
                    <a
                      href={item.link ? localizeHref(item.link) : '#'}
                      className="rp-category-columns__link"
                      {...(item.link &&
                        isExternal(item.link) && {
                          target: '_blank',
                          rel: 'noopener noreferrer',
                        })}
                    >
                      <span className="rp-category-columns__link-text">
                        {item.title}
                      </span>
                      <span className="rp-category-columns__link-arrow">→</span>
                    </a>
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      ))}
    </div>
  );
}

export default CategoryColumns;
