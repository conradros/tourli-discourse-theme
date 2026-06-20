import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import { themePrefix } from "virtual:theme";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { safeColor } from "../lib/tourli-tags";

// Shared destination card grid, used by the home "Featured destinations" row and
// the Destinations directory "With Activity" section. Each card links to the
// tag page. Topic counts are real; replies are not exposed per tag so only
// topics are shown.
export default class TourliDestinationCards extends Component {
  get cards() {
    return (this.args.destinations || []).map((d) => {
      const accent = safeColor(d.color);
      return {
        label: d.label,
        code: d.code,
        blurb: d.blurb,
        topicCount: d.topicCount ?? 0,
        coords: [d.lat, d.lng].filter(Boolean).join(", "),
        href: d.url || `/tag/${d.tag}`,
        style: htmlSafe(`--tl-card-accent: ${accent}`),
      };
    });
  }

  <template>
    <div class="tourli-dest-cards">
      {{#each this.cards as |card|}}
        <a class="tourli-dest-card" href={{card.href}} style={{card.style}}>
          <div class="tourli-dest-card__band">
            {{#if card.code}}
              <span class="tourli-dest-card__code tl-mono">{{card.code}}</span>
            {{/if}}
            {{#if card.coords}}
              <span
                class="tourli-dest-card__coords tl-mono"
              >{{card.coords}}</span>
            {{/if}}
            <span class="tourli-dest-card__label">{{card.label}}</span>
          </div>

          <div class="tourli-dest-card__body">
            {{#if card.blurb}}
              <p class="tourli-dest-card__blurb">{{card.blurb}}</p>
            {{/if}}

            <div class="tourli-dest-card__foot">
              <span class="tourli-dest-card__count">
                {{icon "comment"}}
                {{i18n (themePrefix "tourli.topics") count=card.topicCount}}
              </span>
              <span class="tourli-dest-card__enter">
                {{i18n (themePrefix "tourli.enter")}}
                {{icon "arrow-right"}}
              </span>
            </div>
          </div>
        </a>
      {{/each}}
    </div>
  </template>
}
