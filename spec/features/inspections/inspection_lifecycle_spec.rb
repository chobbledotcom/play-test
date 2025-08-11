# typed: false
# frozen_string_literal: true

# Business Logic: Inspection Lifecycle Management Feature Tests
#
# Tests the user-centric inspection lifecycle management, including:
# - Editing completed inspections (user control maintained)
# - Toggling between complete/incomplete states

require "rails_helper"

RSpec.feature "Inspection Lifecycle Management", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before do
    login_user_via_form(user)
  end

  describe "editing completed inspections" do
    it "prevents editing completed inspections" do
      completed_inspection = create(:inspection, :completed, user: user, unit: unit)

      visit edit_inspection_path(completed_inspection)

      expect(page).to have_current_path(inspection_path(completed_inspection))
      expect_cannot_edit_complete_message
    end

    it "allows marking complete inspection as incomplete" do
      completed_inspection = create(:inspection, :completed, user: user, unit: unit)

      visit edit_inspection_path(completed_inspection)
      click_switch_to_in_progress_button

      expect_marked_in_progress_message
      expect(completed_inspection.reload.complete?).to be false

      # Verify event was logged
      event = Event.where(resource_type: "Inspection", resource_id: completed_inspection.id,
        action: "marked_draft").first
      expect(event).to be_present
      expect(event.user).to eq(user)
    end
  end

  describe "completion workflow" do
    let(:unit) { create(:unit, user: user) }
    let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

    before do
      inspection.un_complete!(user)
    end

    it "can complete inspection" do
      visit edit_inspection_path(inspection)
      click_mark_complete_button
      expect_marked_complete_message
      expect(inspection.reload.complete?).to be true

      # Verify event was logged
      event = Event.where(resource_type: "Inspection", resource_id: inspection.id, action: "completed").first
      expect(event).to be_present
      expect(event.user).to eq(user)
    end
  end

  describe "passed field prefill behavior" do
    it "does not prefill passed field from previous inspection" do
      # Create a completed inspection with passed = true
      create(:inspection, :completed,
        user: user,
        unit: unit,
        passed: true,
        risk_assessment: "Previous risk assessment text")

      # Create a new inspection for the same unit
      visit unit_path(unit)
      click_add_inspection_button

      # Navigate to the results tab
      new_inspection = user.inspections.order(:created_at).last
      visit edit_inspection_path(new_inspection, tab: "results")

      # Check that passed field is NOT pre-filled
      # The pass/fail radio buttons should not have any selection
      within ".form-grid#passed" do
        pass_radio = find('input[type="radio"][value="true"]')
        fail_radio = find('input[type="radio"][value="false"]')

        expect(pass_radio).not_to be_checked
        expect(fail_radio).not_to be_checked
      end

      # But risk_assessment should be pre-filled
      risk_field = find_field(I18n.t("forms.results.fields.risk_assessment"))
      expect(risk_field.value).to eq("Previous risk assessment text")
    end
  end

  describe "inspector company inheritance" do
    it "copies inspector company from user on creation" do
      inspector_company = create(:inspector_company)
      user_with_company = create(:user, inspection_company: inspector_company)
      unit_for_company_user = create(:unit, user: user_with_company)

      expect(user_with_company.inspection_company_id).to eq(inspector_company.id)

      logout
      sign_in(user_with_company)

      initial_count = user_with_company.inspections.count

      visit unit_path(unit_for_company_user)
      click_add_inspection_button

      expect(user_with_company.inspections.count).to eq(initial_count + 1)
      new_inspection = user_with_company.inspections.order(:created_at).last

      expect(new_inspection.user_id).to eq(user_with_company.id)
      expect(new_inspection.inspector_company_id).to eq(inspector_company.id)
    end

    it "allows inspection creation without inspector company" do
      user_without_company = create(:user, inspection_company: nil)
      unit_for_user = create(:unit, user: user_without_company)

      logout
      sign_in(user_without_company)

      initial_count = user_without_company.inspections.count

      visit unit_path(unit_for_user)
      click_add_inspection_button

      expect(user_without_company.inspections.count).to eq(initial_count + 1)
      new_inspection = user_without_company.inspections.order(:created_at).last

      expect(new_inspection.inspector_company_id).to be_nil
      expect(new_inspection).to be_persisted
    end
  end

  describe "photo uploads" do
    let(:inspection) { create(:inspection, user: user, unit: unit) }

    it "allows uploading photos in the results form" do
      visit edit_inspection_path(inspection, tab: "results")

      # Upload photo_1
      within_fieldset(I18n.t("forms.results.sections.photos")) do
        attach_file I18n.t("forms.results.fields.photo_1"),
          Rails.root.join("spec/fixtures/files/test_image.jpg")
        attach_file I18n.t("forms.results.fields.photo_2"),
          Rails.root.join("spec/fixtures/files/test_image.jpg")
        attach_file I18n.t("forms.results.fields.photo_3"),
          Rails.root.join("spec/fixtures/files/test_image.jpg")
      end

      submit_form :results

      expect(page).to have_content(I18n.t("inspections.messages.updated"))

      inspection.reload
      expect(inspection.photo_1.attached?).to be true
      expect(inspection.photo_2.attached?).to be true
      expect(inspection.photo_3.attached?).to be true
    end

    it "displays existing photos when editing" do
      # Attach a photo first
      inspection.photo_1.attach(
        io: Rails.root.join("spec/fixtures/files/test_image.jpg").open,
        filename: "existing.jpg",
        content_type: "image/jpeg"
      )

      visit edit_inspection_path(inspection, tab: "results")

      within_fieldset(I18n.t("forms.results.sections.photos")) do
        expect(page).to have_content("existing.jpg")
      end
    end
  end
end
