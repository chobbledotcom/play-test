require "rails_helper"
require "pdf/inspector"

RSpec.feature "PDF Debug Info", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:unit) { create(:unit, user: admin_user) }
  let(:inspection) { create(:inspection, :completed, user: admin_user, unit: unit) }

  feature "Admin users see debug info in PDFs" do
    scenario "inspection PDF includes debug info page for admin" do
      sign_in(admin_user)

      # Visit the inspection to trigger SQL queries
      visit inspection_path(inspection)

      # Get the PDF
      pdf_text = get_pdf_text("/inspections/#{inspection.id}.pdf")

      # Should include debug info page
      expect(pdf_text).to include(I18n.t("debug.title"))
      expect(pdf_text).to include(I18n.t("debug.query_count"))
      expect(pdf_text).to include(I18n.t("debug.query"))
      expect(pdf_text).to include(I18n.t("debug.duration"))
    end

    scenario "unit PDF includes debug info page for admin" do
      sign_in(admin_user)

      # Visit the unit to trigger SQL queries
      visit unit_path(unit)

      # Get the PDF
      pdf_text = get_pdf_text("/units/#{unit.id}.pdf")

      # Should include debug info page
      expect(pdf_text).to include(I18n.t("debug.title"))
      expect(pdf_text).to include(I18n.t("debug.query_count"))
    end
  end

  feature "Regular users do not see debug info in PDFs" do
    scenario "inspection PDF excludes debug info for regular user" do
      sign_in(regular_user)

      # Transfer ownership for this test
      inspection.update(user: regular_user)

      # Visit the inspection
      visit inspection_path(inspection)

      # Get the PDF
      pdf_text = get_pdf_text("/inspections/#{inspection.id}.pdf")

      # Should NOT include debug info page
      expect(pdf_text).not_to include(I18n.t("debug.title"))
      expect(pdf_text).not_to include(I18n.t("debug.query"))
    end

    scenario "unit PDF excludes debug info for regular user" do
      sign_in(regular_user)

      # Transfer ownership for this test
      unit.update(user: regular_user)

      # Visit the unit
      visit unit_path(unit)

      # Get the PDF
      pdf_text = get_pdf_text("/units/#{unit.id}.pdf")

      # Should NOT include debug info page
      expect(pdf_text).not_to include(I18n.t("debug.title"))
      expect(pdf_text).not_to include(I18n.t("debug.query"))
    end
  end

  feature "Development environment shows debug info" do
    scenario "shows debug info in development even for non-admin" do
      allow(Rails.env).to receive(:development?).and_return(true)

      sign_in(regular_user)
      inspection.update(user: regular_user)

      visit inspection_path(inspection)

      pdf_text = get_pdf_text("/inspections/#{inspection.id}.pdf")

      # Should include debug info in development
      expect(pdf_text).to include(I18n.t("debug.title"))
    end
  end
end

