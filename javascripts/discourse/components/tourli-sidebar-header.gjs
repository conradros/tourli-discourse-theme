import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

// "Tourli Community / N members" block at the top of the sidebar, rendered into
// the before-sidebar-sections outlet. Member count is real data from /about.json;
// if it isn't available the line is simply hidden (no invented numbers).
export default class TourliSidebarHeader extends Component {
  @tracked memberCount = null;

  constructor() {
    super(...arguments);
    this.loadMemberCount();
  }

  async loadMemberCount() {
    try {
      const data = await ajax("/about.json");
      const stats = data?.about?.stats ?? {};
      const key = Object.keys(stats).find(
        (k) => k.includes("user") && k.includes("count")
      );
      if (key && Number.isFinite(stats[key])) {
        this.memberCount = stats[key];
      }
    } catch {
      // Non-fatal: about stats may be hidden for this user; leave count empty.
    }
  }

  <template>
    <div class="tourli-sidebar-header">
      <div class="tourli-sidebar-header__title">Tourli Community</div>
      {{#if this.memberCount}}
        <div class="tourli-sidebar-header__members">
          {{i18n "tourli.members" count=this.memberCount}}
        </div>
      {{/if}}
    </div>
  </template>
}
