import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { relativeAge } from "discourse/lib/formatter";
import { i18n } from "discourse-i18n";
import { publicCategories } from "../lib/tourli-categories";

// Home "Categories" section: real public categories with topic/reply counts and
// the latest topic per category. The latest topics come from a single
// /categories_and_latest.json request (no per-category N+1).
export default class TourliCategoryList extends Component {
  @service site;

  @tracked latestByCategory = {};

  constructor() {
    super(...arguments);
    this.loadLatest();
  }

  get categories() {
    return publicCategories(this.site).map((cat) => {
      const topics = cat.topic_count;
      const replies =
        cat.post_count != null && topics != null
          ? Math.max(cat.post_count - topics, 0)
          : null;
      const isIcon = cat.styleType === "icon" && cat.icon;
      return {
        cat,
        url: cat.url,
        topics,
        replies,
        isIcon,
        iconName: cat.icon,
        prefixStyle: htmlSafe(`--tl-accent: #${cat.color}`),
        latest: this.latestByCategory[cat.id],
      };
    });
  }

  async loadLatest() {
    try {
      const data = await ajax("/categories_and_latest.json");
      const topics = data?.topic_list?.topics || [];
      const users = new Map((data?.users || []).map((u) => [u.id, u]));
      const map = {};

      topics.forEach((topic) => {
        const cid = topic.category_id;
        if (cid == null || map[cid]) {
          return;
        }
        const posters = topic.posters || [];
        const poster =
          posters.find((p) => p.extras?.includes("latest")) ||
          posters[posters.length - 1] ||
          posters[0];
        const user = poster ? users.get(poster.user_id) : null;

        map[cid] = {
          title: topic.title,
          url: `/t/${topic.slug}/${topic.id}`,
          name: user?.name || user?.username,
          avatar: user?.avatar_template?.replace("{size}", "48"),
          age: htmlSafe(relativeAge(new Date(topic.bumped_at))),
        };
      });

      this.latestByCategory = map;
    } catch {
      // Non-fatal: rows just render without the latest-topic column.
    }
  }

  <template>
    <div class="tourli-cat-list">
      {{#each this.categories as |row|}}
        <div class="tourli-cat-row">
          <a class="tourli-cat-row__lead" href={{row.url}}>
            <span class="tourli-cat-row__icon" style={{row.prefixStyle}}>
              {{#if row.isIcon}}
                {{icon row.iconName}}
              {{/if}}
            </span>
            <span class="tourli-cat-row__main">
              <span class="tourli-cat-row__title">{{row.cat.name}}</span>
              {{#if row.cat.descriptionText}}
                <span
                  class="tourli-cat-row__desc"
                >{{row.cat.descriptionText}}</span>
              {{/if}}
              <span class="tourli-cat-row__stats">
                {{#if row.topics}}
                  <span class="tourli-cat-row__stat">
                    {{icon "comment"}}
                    {{i18n "tourli.topics" count=row.topics}}
                  </span>
                {{/if}}
                {{#if row.replies}}
                  <span class="tourli-cat-row__stat">
                    {{icon "reply"}}
                    {{i18n "tourli.replies" count=row.replies}}
                  </span>
                {{/if}}
              </span>
            </span>
          </a>

          {{#if row.latest}}
            <a class="tourli-cat-row__latest" href={{row.latest.url}}>
              {{#if row.latest.avatar}}
                <img
                  class="tourli-cat-row__avatar"
                  src={{row.latest.avatar}}
                  alt=""
                  width="32"
                  height="32"
                />
              {{/if}}
              <span class="tourli-cat-row__latest-text">
                <span class="tourli-cat-row__latest-title">
                  {{row.latest.title}}
                </span>
                <span class="tourli-cat-row__latest-meta">
                  {{#if row.latest.name}}{{row.latest.name}} · {{/if}}
                  {{row.latest.age}}
                </span>
              </span>
            </a>
          {{/if}}
        </div>
      {{/each}}
    </div>
  </template>
}
