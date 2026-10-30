# typed: false

require "rails_helper"

RSpec.feature "Browser database concurrency", type: :feature do
  scenario "serves an authenticated page during a read snapshot", js: true do
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

  scenario "keeps draft PDFs available across pooled connections" do
    user = create(:user)
    unit = create(:unit, user:)
    previous_access = 1.day.ago
    inspection = create(:inspection, user:, unit:,
      pdf_last_accessed_at: previous_access)
    pool = ActiveRecord::Base.connection_pool
    spare_connection = pool.checkout

    sign_in(user)
    visit inspection_path(inspection, format: :pdf)
    expect(page.source).to start_with("%PDF")

    inspection.update_column(:pdf_last_accessed_at, previous_access)
    pool.checkin(spare_connection)
    spare_connection = nil

    visit inspection_path(inspection, format: :pdf)

    expect(page.source).to start_with("%PDF")
    expect(inspection.reload.pdf_last_accessed_at).to be > previous_access
  ensure
    pool.checkin(spare_connection) if spare_connection
  end
end
