require "rails_helper"
require "pdf/inspector"

RSpec.feature "PDF Generation User Workflows", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user, manufacturer: "Test Manufacturer", serial: "TEST123") }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  before do
    sign_in(user)
  end

  feature "User workflow: Generating PDFs from UI" do
    scenario "user accesses PDF from inspection show page" do
      visit inspection_path(inspection)

      expect(page).to have_css("iframe", wait: 5)

      expect(page).to have_css("iframe[src*='#{inspection.id}']")
      expect(page).to have_css("iframe[src*='pdf']")
    end

    scenario "user generates PDF with full assessment workflow" do
      full_inspection = create(:inspection, user: user, unit: unit)

      visit inspection_path(full_inspection)

      expect(page).to have_css("iframe", wait: 5)

      get_pdf("/inspections/#{full_inspection.id}.pdf")
    end

    scenario "user shares public report link" do
      visit inspection_path(inspection)

      expect(page).to have_link(href: /\.pdf/)

      get_pdf("/inspections/#{inspection.id}.pdf")
    end
  end

  feature "User workflow: Unit history reports" do
    scenario "user generates unit report from unit show page" do
      3.times do |i|
        create(:inspection, :completed,
          user: user,
          unit: unit,
          inspection_date: i.months.ago,
          passed: i.even?)
      end

      visit unit_path(unit)

      expect(page).to have_content(I18n.t("units.fields.qr_code"))
      expect(page).to have_link(I18n.t("units.fields.qr_code"), href: unit_path(unit, format: :png))

      pdf_text = get_pdf_text("/units/#{unit.id}.pdf")

      expect(pdf_text).to include(I18n.t("pdf.unit.inspection_history"))
    end

    scenario "user accesses empty unit report" do
      empty_unit = create(:unit, user: user, name: "Empty Unit")

      visit unit_path(empty_unit)

      pdf_text = get_pdf_text("/units/#{empty_unit.id}.pdf")
      expect(pdf_text).to include(I18n.t("pdf.unit.no_completed_inspections"))
    end
  end

  feature "User workflow: Navigation and discovery" do
    scenario "user discovers PDF functionality through inspection list" do
      inspections = create_list(:inspection, 3, :completed, user: user)

      visit inspections_path

      inspections.each do |insp|
        expect(page).to have_content(insp.unit.name) if insp.unit
      end

      click_link inspections.first.unit.name

      expect(current_path).to eq(inspection_path(inspections.first))
      expect(page).to have_css("iframe", wait: 5)
    end

    scenario "user uses search to find inspection and access PDF" do
      searchable_inspection = create(:inspection, :completed,
        user: user,
        unit: unit,
        inspection_location: "Unique Test Location")

      visit inspections_path

      fill_in "query", with: "Unique Test"
      click_button "Search" if page.has_button?("Search")

      expect(page).to have_content("Unique Test Location")

      click_link searchable_inspection.unit.name
      expect(page).to have_css("iframe", wait: 5)
    end
  end

  feature "User workflow: Error handling and feedback" do
    scenario "user encounters missing inspection gracefully" do
      visit "/inspections/NONEXISTENT"

      expect(page.status_code).to eq(404)
    end

    scenario "user tries to access unauthorized inspection" do
      other_user = create(:user)
      other_inspection = create(:inspection, :completed, user: other_user)

      visit inspection_path(other_inspection)

      expect(current_path).to eq(inspection_path(other_inspection))
      expect(page.html).to include("<iframe")
      expect(page.html).to include(inspection_path(other_inspection, format: :pdf))
    end

    scenario "user accesses draft inspection (shows PDF)" do
      draft_inspection = create(:inspection, user: user, complete_date: nil)

      visit inspection_path(draft_inspection)

      expect(page).to have_css("iframe", wait: 5)
      expect(page).to have_content("draft report")
    end
  end

end
