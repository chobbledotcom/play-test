require "rails_helper"

RSpec.feature "JS Add Inspection Debug", type: :feature do
  scenario "clicking add inspection button with JS after registration", js: true do
    # Register a new user like the main test does
    visit root_path
    click_link I18n.t("users.titles.register")

    require_relative "../../../db/seeds/seed_data"
    user_data = SeedData.user_fields
    user_data.each do |field_name, value|
      fill_in I18n.t("forms.user_new.fields.#{field_name}"), with: value
    end

    click_button I18n.t("forms.user_new.submit")

    # Activate the user
    user = User.find_by!(email: user_data[:email])
    user.update!(active_until: 5.minutes.from_now)

    # Refresh page to clear inactive warning
    visit current_path

    puts "=== Starting test after registration ==="

    # Create unit through UI like the main test
    visit root_path
    click_link "Units"
    click_button I18n.t("units.buttons.add_unit")

    # Fill in the form with seed data
    unit_data = SeedData.unit_fields.merge(name: "Debug Test Unit")

    unit_data.each do |field_name, value|
      fill_in I18n.t("forms.units.fields.#{field_name}"), with: value
    end

    # Submit the form
    click_button I18n.t("forms.units.submit")

    # Should be on unit show page now
    puts "After unit creation - URL: #{current_url}"

    # Click on the unit to go to its page
    click_link "Debug Test Unit"

    puts "Current URL: #{current_url}"
    puts "Page title: #{page.title}"

    # Check the button is there
    expect(page).to have_button(I18n.t("units.buttons.add_inspection"))

    # Find the form
    form = all("form").find { |f| f[:action]&.include?("/inspections") }
    if form
      puts "Form found: action=#{form[:action]}, method=#{form[:method]}"
      puts "Form data-turbo: #{form[:"data-turbo"]}"
      puts "Form data-turbo-confirm: #{form[:"data-turbo-confirm"]}"
    else
      puts "No form found for inspections!"
    end

    # Click the button
    puts "=== Clicking button ==="
    click_button I18n.t("units.buttons.add_inspection")

    # Wait a bit
    sleep 2

    puts "=== After click ==="
    puts "Current URL: #{current_url}"
    puts "Page status: #{page.status_code}"

    # Check if we navigated
    if current_path.match?(/inspections\/\w+\/edit/)
      puts "SUCCESS: Navigated to inspection edit page"
      expect(page).to have_content("Edit Inspection")
    else
      puts "FAILED: Still on #{current_path}"
      puts "Page text: #{page.text[0..500]}"

      # Check for any error messages
      if page.has_css?(".flash-error", wait: 0)
        puts "Error flash: #{page.find(".flash-error").text}"
      end
    end
  end

  scenario "running the test 10 times to check consistency", js: true do
    user = create(:user)
    sign_in(user)
    require_relative "../../../db/seeds/seed_data"

    results = []

    10.times do |i|
      # Create unit through UI
      visit root_path
      click_link "Units"
      click_button I18n.t("units.buttons.add_unit")

      unit_data = SeedData.unit_fields.merge(name: "Test Unit #{i}")
      unit_data.each do |field_name, value|
        fill_in I18n.t("forms.units.fields.#{field_name}"), with: value
      end

      click_button I18n.t("forms.units.submit")
      click_link "Test Unit #{i}"

      # Now try to add inspection
      click_button I18n.t("units.buttons.add_inspection")
      sleep 2

      results << if current_path.match?(/inspections\/\w+\/edit/)
        "Run #{i + 1}: SUCCESS"
      else
        "Run #{i + 1}: FAILED (stayed on #{current_path})"
      end
    end

    puts "\n=== RESULTS ==="
    results.each { |r| puts r }

    success_count = results.count { |r| r.include?("SUCCESS") }
    puts "\nSuccess rate: #{success_count}/10"

    expect(success_count).to eq(10), "Expected all runs to succeed, but only #{success_count}/10 did"
  end
end
