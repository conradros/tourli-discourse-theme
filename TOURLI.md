# Tourli Community theme

This is the Discourse **Air** theme rebuilt as **Tourli Community**. All Tourli code
lives in clearly separated files so the theme still updates cleanly from upstream Air:

- `scss/tourli-*.scss` (imported from `common/common.scss`: tokens first, overrides last)
- `javascripts/discourse/components`, `connectors`, `api-initializers`, `lib`
- `assets/fonts/*` (Fraunces, Libre Franklin, IBM Plex Mono, woff2)

Air's own files are barely touched: only `about.json`, `settings.yml`, `locales/en.yml`,
and a 14-line import block in `common/common.scss`. `desktop/`, `mobile/`, and
`common/header.html` are untouched.

## Required site setup (not shippable in the theme)

1. **Activate the color scheme**: Admin → Customize → Themes → Tourli Community →
   set the color palette to **Tourli Light** (and enable **Tourli Dark** as the dark
   palette if you offer dark mode).
2. **Persistent header search field** (matches the mock): Admin → Settings →
   `search_experience` = `search_field`. Leave `enable_welcome_banner` off (the home
   page has its own hero).
3. **Categories & tags** drive the sidebar, banners, home, and directory dynamically.
   Create them per `tourli-discourse/CREATOR_FORUM_CATEGORIES.md` and
   `CUSTOMER_FORUM_CATEGORIES.md`:
   - Public Travellers categories under a parent category (default slug
     `tourli-travellers`).
   - Creator-only categories (private to the creator group).
   - A **Destinations** tag group with the place tags.

## Theme settings (Admin → Customize → Themes → Tourli Community → Settings)

| Setting | Default | Purpose |
|---|---|---|
| `creator_group_name` | `creator_active` | Group that sees the Creator Lounge sidebar + creator banner styling |
| `travellers_parent_slug` | `tourli-travellers` | Parent of the public CATEGORIES section |
| `creator_category_slugs` | 5 creator slugs | Categories in the Creator Lounge section |
| `featured_destinations` | `portugal\|japan\|cape-town` | Home + directory "with activity" cards |
| `destinations` | JSON list | Card visuals + all-tags labels (tag, label, code, color, lat, lng, blurb) |
| `show_header_stats` | `false` | Optional topics/replies line in category banners |
| `destinations_directory_url` | `/tags` | Where the Destinations link points |
| `home_hero_*` | mock copy | Hero eyebrow / headline / accent / subhead |
| `category_accent_overrides` | `{}` | JSON map of category slug to banner accent hex |

## Notes / decisions

- **Real data only**: topics, replies, members, and latest activity come from
  Discourse. Destination cards show **topic counts only** (Discourse does not expose
  reply counts per tag).
- **Sidebar/banners are dynamic** from the real categories/tags, so labels are the
  real category names (not the mock's simplified ones). The Creator Lounge only
  renders for members of `creator_group_name`; access control itself stays in the
  categories' group permissions (the theme never gates access).
- **`/tags` is restyled** into the Destinations directory (default tag cloud hidden).
  Admin tag management still lives under Admin, and non-destination tags
  (`bug`, `feature-request`, `how-to`) remain reachable directly (e.g. `/tag/bug`)
  and via search.
