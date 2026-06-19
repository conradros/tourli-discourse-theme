import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { themePrefix } from "virtual:theme";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { destinations, fetchTagCounts } from "../lib/tourli-tags";
import TourliDestinationCards from "./tourli-destination-cards";

// Destinations directory, rendered into the tags-below-title outlet (/tags).
// "With Activity" reuses the shared cards; "All destination tags" lists every
// configured destination with its real topic count or "No activity yet".
export default class TourliDestinations extends Component {
  @tracked counts = new Map();

  constructor() {
    super(...arguments);
    this.load();
  }

  async load() {
    this.counts = await fetchTagCounts();
  }

  get all() {
    return destinations().map((d) => ({
      ...d,
      topicCount: this.counts.get(d.tag) ?? 0,
    }));
  }

  get active() {
    return this.all.filter((d) => d.topicCount > 0);
  }

  <template>
    <div class="tourli-destinations">
      <div class="tourli-destinations__head">
        <h1 class="tourli-destinations__title">{{i18n
            "tourli.destinations"
          }}</h1>
        <p class="tourli-destinations__subhead">
          {{i18n (themePrefix "tourli.destinations_subhead")}}
        </p>
      </div>

      {{#if this.active.length}}
        <section class="tourli-destinations__section">
          <div class="tl-eyebrow tourli-destinations__eyebrow">
            {{i18n (themePrefix "tourli.with_activity")}}
          </div>
          <TourliDestinationCards @destinations={{this.active}} />
        </section>
      {{/if}}

      <section class="tourli-destinations__section">
        <div class="tl-eyebrow tourli-destinations__eyebrow">
          {{i18n (themePrefix "tourli.all_destination_tags")}}
        </div>
        <div class="tourli-dest-rows">
          {{#each this.all as |dest|}}
            <a class="tourli-dest-row" href="/tag/{{dest.tag}}">
              <span class="tourli-dest-row__name">
                {{icon "map-pin"}}
                {{dest.label}}
              </span>
              {{#if dest.topicCount}}
                <span class="tourli-dest-row__count">
                  {{icon "comment"}}
                  {{i18n (themePrefix "tourli.topics") count=dest.topicCount}}
                </span>
              {{else}}
                <span class="tourli-dest-row__empty">
                  {{i18n (themePrefix "tourli.no_activity_yet")}}
                </span>
              {{/if}}
            </a>
          {{/each}}
        </div>
      </section>
    </div>
  </template>
}
