import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { themePrefix } from "virtual:theme";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { destinationFor, safeColor } from "../lib/tourli-tags";

// Editorial banner at the top of every category and tag page, rendered into the
// discovery-list-controls-above outlet (above the Latest/Top nav, matching the
// mock). One component, fed per-category / per-tag data. Renders nothing on
// pages with neither a category nor a tag (Latest, Top, custom homepage).
export default class TourliBanner extends Component {
  @service composer;
  @service currentUser;

  get category() {
    return this.args.outletArgs?.category;
  }

  get tagName() {
    const tag = this.args.outletArgs?.tag;
    if (!tag) {
      return null;
    }
    return typeof tag === "string" ? tag : (tag.id ?? tag.name ?? null);
  }

  get show() {
    return !!(this.category || this.tagName);
  }

  get isCreator() {
    return !!this.category?.read_restricted;
  }

  get destination() {
    return this.tagName ? destinationFor(this.tagName) : null;
  }

  get title() {
    if (this.category) {
      return this.category.name;
    }
    return this.destination?.label || this.tagName || "";
  }

  get subhead() {
    if (this.category) {
      return this.category.descriptionText;
    }
    return this.destination?.blurb || null;
  }

  get accent() {
    if (this.category) {
      const overrides = this.#accentOverrides();
      const override = overrides[this.category.slug];
      return safeColor(override || `#${this.category.color}`);
    }
    return safeColor(this.destination?.color);
  }

  get bannerStyle() {
    return htmlSafe(`--tl-banner-accent: ${this.accent}`);
  }

  get showStats() {
    return !!(settings.show_header_stats && this.category);
  }

  get stats() {
    const cat = this.category;
    if (!cat) {
      return null;
    }
    const topics = cat.topic_count;
    const replies =
      cat.post_count != null && topics != null
        ? Math.max(cat.post_count - topics, 0)
        : null;
    return { topics, replies, week: cat.topics_week };
  }

  #accentOverrides() {
    try {
      return JSON.parse(settings.category_accent_overrides || "{}") || {};
    } catch {
      return {};
    }
  }

  @action
  createTopic() {
    if (this.category) {
      this.composer.openNewTopic({ category: this.category });
    } else if (this.tagName) {
      this.composer.openNewTopic({ tags: [this.tagName] });
    } else {
      this.composer.openNewTopic({});
    }
  }

  <template>
    {{#if this.show}}
      <div
        class="tourli-banner {{if this.isCreator 'tourli-banner--creator'}}"
        style={{this.bannerStyle}}
      >
        <div class="tourli-banner__texture"></div>

        <div class="tourli-banner__body">
          <nav class="tourli-banner__crumbs">
            <a href="/">{{i18n (themePrefix "tourli.community")}}</a>
            {{icon "angle-right"}}
            <span>{{this.title}}</span>
          </nav>

          {{#if this.isCreator}}
            <div class="tourli-banner__eyebrow tl-eyebrow">
              {{icon "lock"}}
              <span>{{i18n
                  (themePrefix "tourli.creator_lounge_eyebrow")
                }}</span>
            </div>
          {{/if}}

          <h1 class="tourli-banner__title">{{this.title}}</h1>

          {{#if this.subhead}}
            <p class="tourli-banner__subhead">{{this.subhead}}</p>
          {{/if}}

          {{#if this.showStats}}
            <div class="tourli-banner__stats tl-mono">
              {{#if this.stats.topics}}
                <span>{{i18n
                    (themePrefix "tourli.topics")
                    count=this.stats.topics
                  }}</span>
              {{/if}}
              {{#if this.stats.replies}}
                <span>{{i18n
                    (themePrefix "tourli.replies")
                    count=this.stats.replies
                  }}</span>
              {{/if}}
              {{#if this.stats.week}}
                <span>{{i18n
                    "tourli.active_this_week"
                    count=this.stats.week
                  }}</span>
              {{/if}}
            </div>
          {{/if}}
        </div>

        {{#if this.currentUser}}
          <button
            type="button"
            class="tl-pill-btn tourli-banner__action"
            {{on "click" this.createTopic}}
          >
            {{icon "plus"}}
            <span>{{i18n (themePrefix "tourli.new_topic")}}</span>
          </button>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
