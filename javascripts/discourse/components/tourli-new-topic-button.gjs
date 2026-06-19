import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

// Teal "New topic" pill in the header icons row (placed after the search slot).
// Rendered only for logged-in users; anonymous visitors get the native auth
// buttons instead and cannot create topics anyway.
export default class TourliNewTopicButton extends Component {
  @service composer;
  @service currentUser;

  @action
  createTopic() {
    this.composer.openNewTopic({});
  }

  <template>
    {{#if this.currentUser}}
      <li class="tourli-new-topic">
        <button
          type="button"
          class="tl-pill-btn tourli-new-topic__btn"
          {{on "click" this.createTopic}}
        >
          {{icon "plus"}}
          <span>{{i18n "tourli.new_topic"}}</span>
        </button>
      </li>
    {{/if}}
  </template>
}
