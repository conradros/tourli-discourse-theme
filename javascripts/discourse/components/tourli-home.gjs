import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { featuredTags, fetchDestinations } from "../lib/tourli-tags";
import TourliCategoryList from "./tourli-category-list";
import TourliDestinationCards from "./tourli-destination-cards";

// Custom homepage: hero + featured destinations + categories. Copy comes from
// theme settings; destination counts and category data are real.
export default class TourliHome extends Component {
  @service composer;
  @service currentUser;

  @tracked featured = [];

  constructor() {
    super(...arguments);
    this.loadFeatured();
  }

  async loadFeatured() {
    const all = await fetchDestinations();
    const byTag = new Map(all.map((d) => [d.tag, d]));
    const ordered = featuredTags()
      .map((tag) => byTag.get(tag))
      .filter(Boolean);
    // Configured featured order, intersected with real tags. If none of the
    // featured tags exist, show the three most active destinations instead.
    this.featured = ordered.length
      ? ordered
      : [...all].sort((a, b) => b.topicCount - a.topicCount).slice(0, 3);
  }

  get destinationsUrl() {
    return settings.destinations_directory_url || "/tags";
  }

  @action
  createTopic() {
    this.composer.openNewTopic({});
  }

  <template>
    <div class="tourli-home">
      <section class="tourli-hero">
        <div class="tourli-hero__body">
          {{#if settings.home_hero_eyebrow}}
            <div class="tl-eyebrow tourli-hero__eyebrow">
              {{settings.home_hero_eyebrow}}
            </div>
          {{/if}}
          <h1 class="tourli-hero__headline">
            {{settings.home_hero_headline}}
            {{#if settings.home_hero_accent}}
              <span
                class="tl-italic-accent"
              >{{settings.home_hero_accent}}</span>
            {{/if}}
          </h1>
          {{#if settings.home_hero_subhead}}
            <p class="tourli-hero__subhead">{{settings.home_hero_subhead}}</p>
          {{/if}}
        </div>

        {{#if this.currentUser}}
          <button
            type="button"
            class="tl-pill-btn tourli-hero__action"
            {{on "click" this.createTopic}}
          >
            {{icon "plus"}}
            <span>{{i18n (themePrefix "tourli.new_topic")}}</span>
          </button>
        {{/if}}
      </section>

      {{#if this.featured.length}}
        <section class="tourli-section">
          <div class="tourli-section__head">
            <h2 class="tourli-section__title">
              {{i18n (themePrefix "tourli.featured_destinations")}}
            </h2>
            <a class="tourli-section__more" href={{this.destinationsUrl}}>
              {{i18n (themePrefix "tourli.browse_all_destinations")}}
              {{icon "arrow-right"}}
            </a>
          </div>
          <TourliDestinationCards @destinations={{this.featured}} />
        </section>
      {{/if}}

      <section class="tourli-section">
        <div class="tourli-section__head">
          <h2 class="tourli-section__title">
            {{i18n (themePrefix "tourli.categories_heading")}}
          </h2>
        </div>
        <TourliCategoryList />
      </section>
    </div>
  </template>
}
