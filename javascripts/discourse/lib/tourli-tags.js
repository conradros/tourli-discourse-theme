// Destinations are sourced from the real "Destinations" tag group on the site.
// The list (which tags, their numeric ids, slugs, and topic counts) is live;
// the theme setting only supplies optional visuals (label, country code, accent
// color, coordinates, blurb) overlaid onto a matching tag. Tags in the group
// with no overlay entry get a humanized label and the default accent.

import { ajax } from "discourse/lib/ajax";
import getURL from "discourse/lib/get-url";

let _overlay = null;
let _destinationsPromise = null;

// Settings JSON parsed into a Map keyed by tag slug: the visual overlay.
function overlay() {
  if (_overlay) {
    return _overlay;
  }
  const raw = settings.destinations;
  let list;
  if (Array.isArray(raw)) {
    list = raw;
  } else {
    try {
      list = JSON.parse(raw || "[]");
    } catch {
      list = [];
    }
  }
  _overlay = new Map(
    (list || []).filter((d) => d && d.tag).map((d) => [d.tag, d])
  );
  return _overlay;
}

// Visual overlay for a single tag (used by the banner on tag pages). Synchronous.
export function destinationFor(tagName) {
  return tagName ? overlay().get(tagName) || null : null;
}

const HEX_RE = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i;

// Validate a hex color before it is injected into inline styles / gradients.
export function safeColor(value, fallback = "#205d5e") {
  const v = (value || "").trim();
  return HEX_RE.test(v) ? v : fallback;
}

export function destinationsTagGroupName() {
  return (settings.destinations_tag_group || "Destinations").trim();
}

export function featuredTags() {
  if (Array.isArray(settings.featured_destinations)) {
    return settings.featured_destinations.filter(Boolean);
  }
  return String(settings.featured_destinations || "")
    .split("|")
    .map((s) => s.trim())
    .filter(Boolean);
}

// "cape-town" -> "Cape Town" for tags without a configured label.
function humanize(slug) {
  return String(slug || "")
    .split(/[-_]/)
    .filter(Boolean)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

// Build a destination view-model from a real tag, merging the settings overlay.
function decorate({ name, slug, id }, count) {
  const useSlug = slug || name;
  const o = overlay().get(name) || overlay().get(useSlug) || {};
  const url = id
    ? getURL(`/tag/${useSlug}/${id}`)
    : getURL(`/tag/${encodeURIComponent(name)}`);
  return {
    tag: name,
    slug: useSlug,
    id: id ?? null,
    url,
    topicCount: count ?? 0,
    label: o.label || humanize(name),
    code: o.code || "",
    color: o.color || "",
    lat: o.lat || "",
    lng: o.lng || "",
    blurb: o.blurb || "",
  };
}

// Members of the configured Destinations tag group: [{ id, name, slug }].
// Not staff-gated; respects the caller's tag visibility.
async function fetchGroupTags() {
  const name = destinationsTagGroupName();
  const data = await ajax("/tag_groups/filter/search.json", {
    data: { q: name },
  });
  const groups = data?.results || [];
  const match = groups.find(
    (g) => (g.name || "").toLowerCase() === name.toLowerCase()
  );
  return match?.tags || [];
}

// Map of tag name -> real topic count, merged from the flat list and every tag
// group in /tags.json (grouped tags are reported under extras.tag_groups when
// the site lists tags by group, and under the flat list otherwise).
async function fetchTagCounts() {
  const counts = new Map();
  const data = await ajax("/tags.json");
  const lists = [data?.tags || []];
  (data?.extras?.tag_groups || []).forEach((g) => lists.push(g.tags || []));
  lists.forEach((list) =>
    list.forEach((t) => {
      // /tags.json tag objects expose a numeric `id` and a string `name`; key by
      // name so lookups by tag name (from the tag-group endpoint) hit.
      const tagName = t.name ?? t.id;
      if (tagName != null) {
        counts.set(tagName, t.count ?? 0);
      }
    })
  );
  return counts;
}

// Live destinations: the real Destinations-group tags, decorated with overlay
// visuals and real topic counts. If the group can't be read, fall back to the
// configured tags that actually exist on the site (never link to a dead tag).
// Cached for the page so the home, directory, and tag-chip styles share one
// fetch.
export function fetchDestinations() {
  if (_destinationsPromise) {
    return _destinationsPromise;
  }
  _destinationsPromise = (async () => {
    let counts = new Map();
    try {
      counts = await fetchTagCounts();
    } catch {
      // Counts are non-fatal; destinations still render with 0.
    }

    let result = [];
    try {
      const groupTags = await fetchGroupTags();
      if (groupTags.length) {
        result = groupTags.map((t) => decorate(t, counts.get(t.name)));
      }
    } catch {
      // Fall through to the configured-and-real fallback below.
    }

    if (!result.length) {
      // Fallback: configured tags that exist in the live tag list (real counts,
      // legacy slug links that the site redirects to the canonical tag URL).
      result = [...overlay().keys()]
        .filter((tag) => counts.has(tag))
        .map((tag) =>
          decorate({ name: tag, slug: tag, id: null }, counts.get(tag))
        );
    }

    // Don't cache an empty result (typically a transient fetch failure) so the
    // next visit retries instead of showing nothing for the whole session.
    if (!result.length) {
      _destinationsPromise = null;
    }
    return result;
  })();
  return _destinationsPromise;
}

// Real destination tag names (for promoting destination chips on topic rows).
export async function destinationTagNames() {
  const dests = await fetchDestinations();
  return dests.map((d) => d.tag);
}
