# typed: false
# frozen_string_literal: true

namespace :magic_container do
  desc "Create a Bunny Magic Container from a backup archive (interactive)"
  task create: :environment do
    MagicContainer::Wizard.new.call
  end
end
