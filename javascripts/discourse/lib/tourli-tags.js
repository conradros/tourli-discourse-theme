// Destination metadata (from the theme setting) + real tag topic counts.
// Card visuals come from settings; counts come from live tag data.

import { ajax } from "discourse/lib/ajax";

let _destinations = null;

export function destinations() {
  if (_destinations) {
    return _destinations;
  }
  const raw = settings.destinations;
  if (Array.isArray(raw)) {
    _destinations = raw;
  } else {
    try {
      _destinations = JSON.parse(raw || "[]");
    } catch {
      _destinations = [];
    }
  }
  return _destinations;
}

export function destinationFor(tagName) {
  if (!tagName) {
    return null;
  }
  return destinations().find((d) => d.tag === tagName) || null;
}

const HEX_RE = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i;

// Validate a hex color before it is injected into inline styles / gradients.
export function safeColor(value, fallback = "#205d5e") {
  const v = (value || "").trim();
  return HEX_RE.test(v) ? v : fallback;
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

// Map of tag name -> real topic count, from /tags.json. Returns an empty Map on
// failure so callers degrade to "no activity" rather than breaking.
export async function fetchTagCounts() {
  const counts = new Map();
  try {
    const data = await ajax("/tags.json");
    const lists = [data?.tags || []];
    (data?.extras?.tag_groups || []).forEach((g) => lists.push(g.tags || []));
    lists.forEach((list) =>
      list.forEach((t) => {
        const name = t.id ?? t.name;
        if (name != null) {
          counts.set(name, t.count ?? 0);
        }
      })
    );
  } catch {
    // Non-fatal: leave counts empty.
  }
  return counts;
}
