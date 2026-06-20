// Classify the site's real categories into the public Travellers set and the
// creator-only set, driven by theme settings. Everything reads from
// site.categories so names, counts, colors, and visibility are real data.
//
// `settings` is the theme settings global injected into all theme JS modules.

// System categories we never want in the curated public list.
const SYSTEM_SLUGS = ["uncategorized", "staff", "site-feedback"];

export function splitList(value) {
  if (!value) {
    return [];
  }
  if (Array.isArray(value)) {
    return value.filter(Boolean);
  }
  return String(value)
    .split("|")
    .map((s) => s.trim())
    .filter(Boolean);
}

export function creatorCategorySlugs() {
  return splitList(settings.creator_category_slugs);
}

// Creator-only categories, in the order configured by the setting. Only the
// categories the current user can actually see are in site.categories, so this
// is naturally empty for customers and anonymous visitors.
export function creatorCategories(site) {
  const bySlug = new Map(site.categories.map((c) => [c.slug, c]));
  return creatorCategorySlugs()
    .map((slug) => bySlug.get(slug))
    .filter(Boolean);
}

// Public Travellers categories: the children of the configured parent category.
// Falls back to top-level, non-creator, non-system categories if the parent
// isn't found, so the section is never empty just because of a slug mismatch.
export function publicCategories(site) {
  const creatorSet = new Set(creatorCategorySlugs());
  const parentSlug = settings.travellers_parent_slug;
  const parent = parentSlug
    ? site.categories.find(
        (c) => c.slug === parentSlug && !c.parent_category_id
      )
    : null;

  if (parent) {
    return site.categories.filter((c) => c.parent_category_id === parent.id);
  }

  // Parent not found, or not visible to this user (an anonymous visitor often
  // cannot see the Travellers container category even though its children are
  // public). Fall back to every category the user can actually see that is not
  // creator-only or a system category. For anonymous and customer visitors this
  // is exactly the public Travellers set, since creator categories are not in
  // their site.categories at all.
  return site.categories.filter(
    (c) => !creatorSet.has(c.slug) && !SYSTEM_SLUGS.includes(c.slug)
  );
}

export function userInCreatorGroup(currentUser) {
  if (!currentUser) {
    return false;
  }
  if (currentUser.admin) {
    return true;
  }
  const groupName = settings.creator_group_name;
  return !!currentUser.groups?.some((g) => g.name === groupName);
}
