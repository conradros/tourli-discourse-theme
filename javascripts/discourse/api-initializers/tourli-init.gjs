import { themePrefix } from "virtual:theme";
import { apiInitializer } from "discourse/lib/api";
import { getReviewBadgeText } from "discourse/lib/sidebar/helpers/review-badge-helper";
import Category from "discourse/models/category";
import { i18n } from "discourse-i18n";
import TourliBanner from "../components/tourli-banner";
import TourliSidebarHeader from "../components/tourli-sidebar-header";
import {
  creatorCategories,
  publicCategories,
  userInCreatorGroup,
} from "../lib/tourli-categories";
import { destinationTagNames } from "../lib/tourli-tags";

// Promote destination tags on topic rows: a pin glyph, teal chip, and ordered
// first. The tag list comes from the live Destinations group, so the CSS is
// generated once after that resolves. Sanitized to slug characters.
async function injectDestinationTagStyles() {
  if (document.getElementById("tourli-destination-tags")) {
    return;
  }
  let tags = [];
  try {
    tags = await destinationTagNames();
  } catch {
    return;
  }
  tags = tags.filter((t) => /^[a-z0-9-]+$/i.test(t));
  if (!tags.length || document.getElementById("tourli-destination-tags")) {
    return;
  }
  const selector = (suffix) =>
    tags
      .map((t) => `.topic-list .discourse-tag[data-tag-name="${t}"]${suffix}`)
      .join(",\n");
  const pin =
    "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%20384%20512'%3E%3Cpath%20d='M215.7%20499.2C267%20435%20384%20279.4%20384%20192C384%2086%20298%200%20192%200S0%2086%200%20192c0%2087.4%20117%20243%20168.3%20307.2c12.3%2015.3%2035.1%2015.3%2047.4%200zM192%20128a64%2064%200%201%201%200%20128%2064%2064%200%201%201%200-128z'/%3E%3C/svg%3E";
  const style = document.createElement("style");
  style.id = "tourli-destination-tags";
  style.textContent = `
${selector("")} {
  order: -1;
  color: var(--tl-teal);
  font-weight: 600;
  background: color-mix(in srgb, var(--tl-teal) 12%, transparent);
}
${selector("::before")} {
  content: "";
  display: inline-block;
  width: 0.8em;
  height: 0.8em;
  margin-right: 0.3em;
  vertical-align: -0.08em;
  background: currentcolor;
  mask: url("${pin}") no-repeat center / contain;
  -webkit-mask: url("${pin}") no-repeat center / contain;
}`;
  document.head.appendChild(style);
}

// Tourli Community wiring. Kept in one api-initializer so the theme's JS surface
// is easy to scan. Each block is independent and guarded.
export default apiInitializer((api) => {
  const site = api.container.lookup("service:site");
  const currentUser = api.container.lookup("service:current-user");

  injectDestinationTagStyles();

  // -------------------------------------------------------------------------
  // Sidebar header: the "Tourli Community" block above all sections.
  // -------------------------------------------------------------------------
  api.renderInOutlet("before-sidebar-sections", TourliSidebarHeader);

  // -------------------------------------------------------------------------
  // Editorial banner on every category + tag page (above the Latest/Top nav).
  // -------------------------------------------------------------------------
  api.renderInOutlet("discovery-list-controls-above", TourliBanner);

  // -------------------------------------------------------------------------
  // Sidebar sections (dynamic from real categories).
  // -------------------------------------------------------------------------
  // A category link that mirrors core prefix/route behavior. No count badge:
  // Tourli does not show topic counts in the sidebar.
  function buildCategoryLink(BaseLink) {
    return class extends BaseLink {
      constructor(category) {
        super();
        this.category = category;
      }

      get name() {
        return `tourli-category-${this.category.id}`;
      }

      get route() {
        return "discovery.category";
      }

      get model() {
        return `${Category.slugFor(this.category)}/${this.category.id}`;
      }

      get title() {
        return this.category.descriptionText;
      }

      get text() {
        return this.category.displayName;
      }

      get prefixType() {
        return this.category.styleType;
      }

      get prefixValue() {
        const styleType = this.category.styleType;
        if (styleType === "icon") {
          return this.category.icon;
        }
        if (styleType === "emoji") {
          return this.category.emoji;
        }
        if (this.category.parentCategory?.color) {
          return [this.category.parentCategory.color, this.category.color];
        }
        return [this.category.color];
      }

      get prefixColor() {
        return this.category.color;
      }

      get prefixBadge() {
        return this.category.read_restricted ? "category.restricted" : null;
      }

      get badgeText() {
        return null;
      }
    };
  }

  // The "Destinations" link points at the tags directory and is labelled "tags".
  function buildDestinationsLink(BaseLink) {
    return class extends BaseLink {
      get name() {
        return "tourli-destinations";
      }

      get href() {
        return settings.destinations_directory_url || "/tags";
      }

      get title() {
        return i18n(themePrefix("tourli.destinations"));
      }

      get text() {
        return i18n(themePrefix("tourli.destinations"));
      }

      get prefixType() {
        return "icon";
      }

      get prefixValue() {
        return "map-pin";
      }

      get badgeText() {
        return i18n(themePrefix("tourli.tags_suffix"));
      }
    };
  }

  // CATEGORIES: public Travellers categories + Destinations.
  api.addSidebarSection(
    (BaseCustomSidebarSection, BaseCustomSidebarSectionLink) => {
      const CategoryLink = buildCategoryLink(BaseCustomSidebarSectionLink);
      const DestinationsLink = buildDestinationsLink(
        BaseCustomSidebarSectionLink
      );

      return class extends BaseCustomSidebarSection {
        get name() {
          return "tourli-categories";
        }

        get text() {
          return i18n(themePrefix("tourli.categories_heading"));
        }

        get displaySection() {
          return publicCategories(site).length > 0;
        }

        get links() {
          const links = publicCategories(site).map(
            (category) => new CategoryLink(category)
          );
          links.push(new DestinationsLink());
          return links;
        }
      };
    }
  );

  // CREATOR LOUNGE: private creator categories. Only rendered for members of the
  // creator group (theme setting) who can actually see the categories.
  api.addSidebarSection(
    (BaseCustomSidebarSection, BaseCustomSidebarSectionLink) => {
      const CategoryLink = buildCategoryLink(BaseCustomSidebarSectionLink);

      return class extends BaseCustomSidebarSection {
        get name() {
          return "tourli-creator-lounge";
        }

        get text() {
          return i18n(themePrefix("tourli.creator_lounge_heading"));
        }

        get displaySection() {
          return (
            userInCreatorGroup(currentUser) &&
            creatorCategories(site).length > 0
          );
        }

        get links() {
          return creatorCategories(site).map(
            (category) => new CategoryLink(category)
          );
        }
      };
    }
  );

  // QUICK LINKS: My Posts + Bookmarks (header hidden via CSS), logged-in only.
  api.addSidebarSection(
    (BaseCustomSidebarSection, BaseCustomSidebarSectionLink) => {
      class MyPostsLink extends BaseCustomSidebarSectionLink {
        get name() {
          return "tourli-my-posts";
        }

        get route() {
          return "userActivity.index";
        }

        get model() {
          return currentUser;
        }

        get title() {
          return i18n(themePrefix("tourli.my_posts"));
        }

        get text() {
          return i18n(themePrefix("tourli.my_posts"));
        }

        get prefixType() {
          return "icon";
        }

        get prefixValue() {
          return "comment";
        }
      }

      class BookmarksLink extends BaseCustomSidebarSectionLink {
        get name() {
          return "tourli-bookmarks";
        }

        get route() {
          return "userActivity.bookmarks";
        }

        get model() {
          return currentUser;
        }

        get title() {
          return i18n(themePrefix("tourli.bookmarks"));
        }

        get text() {
          return i18n(themePrefix("tourli.bookmarks"));
        }

        get prefixType() {
          return "icon";
        }

        get prefixValue() {
          return "bookmark";
        }
      }

      // Staff links live in the default Community section, which Tourli hides, so
      // re-add Review (for reviewers) and Admin (for staff) here. Mirrors core's
      // routes/icons; Review carries the pending-count badge.
      class ReviewLink extends BaseCustomSidebarSectionLink {
        get name() {
          return "tourli-review";
        }

        get route() {
          return "review";
        }

        get title() {
          return i18n(themePrefix("tourli.review"));
        }

        get text() {
          return i18n(themePrefix("tourli.review"));
        }

        get prefixType() {
          return "icon";
        }

        get prefixValue() {
          return "flag";
        }

        get badgeText() {
          return getReviewBadgeText(currentUser);
        }
      }

      class AdminLink extends BaseCustomSidebarSectionLink {
        get name() {
          return "tourli-admin";
        }

        get route() {
          return "admin";
        }

        get title() {
          return i18n(themePrefix("tourli.admin"));
        }

        get text() {
          return i18n(themePrefix("tourli.admin"));
        }

        get prefixType() {
          return "icon";
        }

        get prefixValue() {
          return "wrench";
        }
      }

      return class extends BaseCustomSidebarSection {
        get name() {
          return "tourli-quick-links";
        }

        get text() {
          return i18n(themePrefix("tourli.quick_links"));
        }

        get displaySection() {
          return !!currentUser;
        }

        get links() {
          const links = [new MyPostsLink(), new BookmarksLink()];
          if (currentUser?.can_review) {
            links.push(new ReviewLink());
          }
          if (currentUser?.staff) {
            links.push(new AdminLink());
          }
          return links;
        }
      };
    }
  );
});
