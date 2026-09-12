# typed: false

require "rails_helper"

RSpec.feature "Browser database concurrency", js: true do
  scenario "serves an authenticated page while the test holds a read snapshot" do
    user = create(:user)
    sign_in(user)
    previous_activity = 1.day.ago
    user.update!(last_active_at: previous_activity)

    ActiveRecord::Base.connection_pool.with_connection do |connection|
      # Hold a reader open while the browser's activity callback writes users.
      connection.raw_connection.transaction(:deferred) do |database|
        database.execute("SELECT * FROM users")
        visit units_path
        expect(page).to have_content(I18n.t("units.titles.index"))
        expect(page).to have_current_path(units_path)
      end
    end

    expect(user.reload.last_active_at).to be > previous_activity
  end
end
