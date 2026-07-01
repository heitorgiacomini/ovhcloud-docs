import type { NormalizedSidebarGroup, SidebarData } from '@rspress/core';
import { useActiveMatcher } from '@rspress/core/runtime';
import {
  createContext,
  useContext,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { isSidebarGroup } from './utils';

/**
 * Location-aware active-branch resolution for multi-located guides.
 *
 * ~12% of guides are listed in more than one sidebar group (e.g. the SSH
 * introduction lives under both Dedicated Servers and VPS). Rspress keys
 * "active" purely off the link string, so every branch containing the link
 * expands and each active DOM node fights over `scrollIntoView`.
 *
 * We instead resolve a SINGLE active instance, identified by its position in
 * the tree (the same `id` path SidebarGroup already uses, e.g. "3-2-1").
 * Selection order:
 *   1. If the user just clicked a specific sidebar instance, that instance.
 *   2. Else, the candidate whose tree path shares the longest prefix with the
 *      previously-active instance — i.e. keep the customer in the branch they
 *      were browsing (works even when both branches share a top-level product
 *      family and diverge only at the sub-group).
 *   3. Else (cold deep-link / search / external entry), the first candidate
 *      in tree order — the guide's canonical (first-listed) branch.
 *
 * The chosen branch is persisted in sessionStorage so it survives in-SPA
 * navigations and reloads within the session.
 */

const STORAGE_KEY = 'ovh.sidebar.activeBranch';

interface ActiveBranchContextValue {
  /** Full tree-path id of the single resolved-active instance, or null. */
  activeId: string | null;
  /** Record that the user clicked a specific instance (by its tree-path id). */
  notifyClick: (id: string) => void;
}

const ActiveBranchContext = createContext<ActiveBranchContextValue>({
  activeId: null,
  notifyClick: () => {},
});

/**
 * Number of leading id segments two instance paths share. Multi-located guides
 * often live under the SAME top-level product family (e.g. both SSH instances
 * sit under "Bare Metal Cloud", diverging only at the product sub-group
 * Dedicated Servers vs Virtual Private Servers). So a branch must be
 * identified by its FULL path, and "same branch as before" means the candidate
 * whose path shares the longest prefix with the previously-active one.
 */
function sharedPrefixLength(a: string, b: string): number {
  const pa = a.split('-');
  const pb = b.split('-');
  let n = 0;
  while (n < pa.length && n < pb.length && pa[n] === pb[n]) n++;
  return n;
}

/** True when `groupId` is an ancestor of (or equal to) `id`. */
export function isAncestorId(groupId: string, id: string | null): boolean {
  if (!id) return false;
  return id === groupId || id.startsWith(`${groupId}-`);
}

type SidebarNode = SidebarData[number];

/**
 * Walk the sidebar tree and collect the tree-path id of every instance whose
 * link matches the active route, in depth-first (tree) order.
 */
function collectCandidates(
  data: SidebarData,
  activeMatcher: (link: string) => boolean,
): string[] {
  const candidates: string[] = [];
  const visit = (node: SidebarNode, id: string): void => {
    if ('link' in node && node.link && activeMatcher(node.link)) {
      candidates.push(id);
    }
    if (isSidebarGroup(node)) {
      (node as NormalizedSidebarGroup).items.forEach((child, index) => {
        visit(child as SidebarNode, `${id}-${index}`);
      });
    }
  };
  data.forEach((node, index) => {
    visit(node, String(index));
  });
  return candidates;
}

/** All ancestor-group ids of an instance id, excluding the instance itself. */
function ancestorIdsOf(id: string): string[] {
  const parts = id.split('-');
  const ancestors: string[] = [];
  for (let i = 1; i < parts.length; i++) {
    ancestors.push(parts.slice(0, i).join('-'));
  }
  return ancestors;
}

/** Read `collapsed` of the group at `groupId`, or undefined if not a group. */
function getCollapsedAt(
  data: SidebarData,
  groupId: string,
): boolean | undefined {
  const indexes = groupId.split('-').map(Number);
  let current: SidebarNode | undefined = data[indexes[0]];
  for (let i = 1; i < indexes.length && current; i++) {
    if (!isSidebarGroup(current)) return undefined;
    current = (current as NormalizedSidebarGroup).items[
      indexes[i]
    ] as SidebarNode;
  }
  return current && 'items' in current
    ? (current as NormalizedSidebarGroup).collapsed
    : undefined;
}

/** Set `collapsed` on the group at `groupId` within a cloned tree. */
function setCollapsedAt(
  data: SidebarData,
  groupId: string,
  collapsed: boolean,
): void {
  const indexes = groupId.split('-').map(Number);
  let current: SidebarNode | undefined = data[indexes[0]];
  for (let i = 1; i < indexes.length && current; i++) {
    if (!isSidebarGroup(current)) return;
    current = (current as NormalizedSidebarGroup).items[
      indexes[i]
    ] as SidebarNode;
  }
  if (current && 'items' in current) {
    (current as NormalizedSidebarGroup).collapsed = collapsed;
  }
}

/**
 * Reconcile branch expansion for a multi-located guide:
 *  - collapse, for each non-resolved candidate, its SHALLOWEST ancestor group
 *    not shared with the resolved instance (closes the whole wrong branch);
 *  - (re-)open every ancestor of the resolved instance, so a branch that a
 *    prior transient resolution had collapsed is corrected in the same pass.
 * The shared product family (a common ancestor) is thus always left open.
 * Returns a new (mutated clone) sidebar tree; the caller passes the previous
 * state. Returns the input unchanged when nothing needs to move.
 */
function collapseAncestorsOf(
  data: SidebarData,
  nonResolved: string[],
  activeId: string,
): SidebarData {
  const openIds = ancestorIdsOf(activeId);
  const keepOpen = new Set([activeId, ...openIds]);
  const collapseIds = new Set<string>();
  for (const id of nonResolved) {
    // ancestorIdsOf returns shallow→deep; the first not shared with the
    // resolved instance is the divergence point for this branch.
    const divergent = ancestorIdsOf(id).find((a) => !keepOpen.has(a));
    if (divergent) collapseIds.add(divergent);
  }
  if (collapseIds.size === 0) return data;

  // No-op guard: if the tree is already in the desired state, return the SAME
  // reference so React skips a needless re-render (and so this function can
  // never drive a render loop even if effect deps change in future).
  const alreadyDone =
    openIds.every((id) => getCollapsedAt(data, id) !== true) &&
    [...collapseIds].every((id) => getCollapsedAt(data, id) === true);
  if (alreadyDone) return data;

  const clone = structuredClone(data);
  for (const id of openIds) setCollapsedAt(clone, id, false);
  for (const id of collapseIds) setCollapsedAt(clone, id, true);
  return clone;
}

function readStoredBranch(): string | null {
  try {
    return sessionStorage.getItem(STORAGE_KEY);
  } catch {
    // sessionStorage unavailable — fall back to canonical.
    return null;
  }
}

function writeStoredBranch(branch: string): void {
  try {
    sessionStorage.setItem(STORAGE_KEY, branch);
  } catch {
    // ignore
  }
}

export function ActiveBranchProvider({
  sidebarData,
  setSidebarData,
  children,
}: {
  sidebarData: SidebarData;
  setSidebarData: React.Dispatch<React.SetStateAction<SidebarData>>;
  children: React.ReactNode;
}) {
  const activeMatcher = useActiveMatcher();

  const rawCandidates = useMemo(
    () => collectCandidates(sidebarData, activeMatcher),
    [sidebarData, activeMatcher],
  );
  // Stabilise the reference so a `collapsed`-only change to sidebarData (e.g.
  // our own correction below, or a user toggle) doesn't recompute a new array
  // and re-fire route-scoped effects. The candidate ID set only truly changes
  // when the route changes.
  const candidatesKey = rawCandidates.join('|');
  // biome-ignore lint/correctness/useExhaustiveDependencies: keyed by candidatesKey
  const candidates = useMemo(() => rawCandidates, [candidatesKey]);

  // The instance the user most recently clicked, if any. A click happens on
  // the SOURCE page and navigates to the DESTINATION route, so we can't key it
  // on the current route — we key on the instance id itself and consume it
  // once that id shows up among the destination route's candidates.
  const clickedRef = useRef<string | null>(null);

  // SSR / first paint: deterministic canonical fallback (first candidate), so
  // server and client agree before the client reconciles to the preserved
  // branch. `mounted` flips true after the first layout effect on the client.
  const [mounted, setMounted] = useState(false);
  useLayoutEffect(() => setMounted(true), []);

  const activeId = useMemo<string | null>(() => {
    if (candidates.length === 0) return null;
    if (candidates.length === 1) return candidates[0];

    // Multi-located guide: pick a single instance.
    if (!mounted) {
      // Canonical fallback for SSR / pre-hydration.
      return candidates[0];
    }

    // 1. Just-clicked instance wins, once its destination route resolves to a
    //    candidate set that includes it.
    const clicked = clickedRef.current;
    if (clicked && candidates.includes(clicked)) {
      return clicked;
    }

    // 2. Preserve the previously-active branch: among candidates, the one
    //    whose tree path shares the longest prefix with the last active
    //    instance. This keeps the customer in e.g. the VPS branch even though
    //    both branches sit under the same Bare Metal Cloud family. Requires a
    //    real shared prefix (> 0) so an unrelated stored branch doesn't win by
    //    default; ties fall through to tree order (canonical).
    const storedId = readStoredBranch();
    if (storedId) {
      let best: string | null = null;
      let bestLen = 0;
      for (const id of candidates) {
        const len = sharedPrefixLength(id, storedId);
        if (len > bestLen) {
          bestLen = len;
          best = id;
        }
      }
      if (best) return best;
    }

    // 3. Canonical: first candidate in tree order.
    return candidates[0];
  }, [candidates, mounted]);

  // Persist the resolved instance (full path) for subsequent navigations in
  // this session, and consume the click once it has been honoured so a later
  // deep-link entry falls back to the preserved/canonical branch rather than a
  // stale click.
  //
  // Gate on `mounted`: before mount the memo returns the canonical placeholder
  // (candidates[0]) to keep SSR/hydration deterministic. Persisting that
  // placeholder would overwrite the incoming stored branch BEFORE the
  // post-mount re-resolution gets to read it, defeating branch preservation on
  // a hard navigation/reload. So we only persist once resolution is final.
  useLayoutEffect(() => {
    if (!mounted || !activeId) return;
    writeStoredBranch(activeId);
    if (clickedRef.current === activeId) clickedRef.current = null;
  }, [activeId, mounted]);

  // Rspress's createInitialSidebar auto-expands EVERY group that contains the
  // active link — so a multi-located guide opens all of its branches. Once we
  // have resolved a single active instance, re-collapse the branches that were
  // only expanded because they hold a NON-resolved candidate. Groups that are
  // ancestors of the resolved instance are left untouched (they must stay
  // open).
  //
  // This MUST be a passive effect (useEffect), not useLayoutEffect: Rspress's
  // own useSidebarDynamic runs a useLayoutEffect that rebuilds+re-expands the
  // sidebar on every route change. Child layout effects fire before the
  // parent's, so a layout-effect collapse here would be clobbered by Rspress's
  // re-expansion. A passive effect runs after all layout effects, so our
  // collapse wins. Keyed on the resolved id + candidate set so it runs once
  // per route, not on every user toggle within the same page — leaving manual
  // expand/collapse intact.
  useEffect(() => {
    if (!mounted || !activeId || candidates.length < 2) return;
    const toCollapse = candidates.filter(
      (id) => id !== activeId && !isAncestorId(id, activeId),
    );
    if (toCollapse.length === 0) return;
    setSidebarData((data) => collapseAncestorsOf(data, toCollapse, activeId));
  }, [mounted, activeId, candidates, setSidebarData]);

  const value = useMemo<ActiveBranchContextValue>(
    () => ({
      activeId,
      notifyClick: (id: string) => {
        clickedRef.current = id;
      },
    }),
    [activeId],
  );

  return (
    <ActiveBranchContext.Provider value={value}>
      {children}
    </ActiveBranchContext.Provider>
  );
}

export function useActiveBranch(): ActiveBranchContextValue {
  return useContext(ActiveBranchContext);
}
