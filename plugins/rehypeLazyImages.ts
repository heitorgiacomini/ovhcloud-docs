/**
 * Rehype plugin that adds loading="lazy" and decoding="async" to all <img>
 * elements in the final HTML output.
 *
 * This is a catch-all for markdown image syntax `![alt](/path)` which Rspress
 * converts to plain <img> tags, as well as inline <img> JSX in MDX files.
 *
 * Images with an explicit loading or decoding attribute are left untouched.
 */
import type { Element, Root } from 'hast';
import { visit } from 'unist-util-visit';

export function rehypeLazyImages() {
  return (tree: Root) => {
    visit(tree, 'element', (node: Element) => {
      if (node.tagName !== 'img') return;
      if (!node.properties) node.properties = {};
      if (!node.properties.loading) node.properties.loading = 'lazy';
      if (!node.properties.decoding) node.properties.decoding = 'async';
    });
  };
}
