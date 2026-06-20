# frozen_string_literal: true

RSpec.describe "Core features" do
  before { upload_theme_or_component }

  # Tourli Community ships a custom homepage (modifiers.custom_homepage) and
  # replaces the default sidebar sections with its own. As a result "/" no longer
  # renders the core topic list or the default categories sidebar section, so the
  # core-feature examples that start from "/" and look for those (reading,
  # creating, replying to topics, and liking, which all reach a topic via "/")
  # cannot pass. Those are skipped here; login, search, profile, and plugin-asset
  # examples still run and confirm the theme does not break core behaviour.
  it_behaves_like "having working core features",
                  skip_examples: [:"topics:read", :"topics:create", :"topics:reply", :likes]
end
