require "rails_helper"

RSpec.describe InspectionsHelper, type: :helper do
  describe "#format_inspection_count" do
    it "formats the inspection count" do
      user = double("User", inspections: double("Inspections", count: 5))
      expect(helper.format_inspection_count(user)).to eq("5 inspections")
    end
  end

  describe "#inspection_tabs" do
    let(:user) { create(:user) }
    let(:inspection) { create(:inspection, user: user) }

    it "returns standard tabs for regular units" do
      tabs = helper.inspection_tabs(inspection)
      expect(tabs).to eq(%w[general user_height structure anchorage materials fan])
    end

    it "includes enclosed tab for totally enclosed units" do
      unit = create(:unit)
      inspection.update!(unit: unit, is_totally_enclosed: true)

      tabs = helper.inspection_tabs(inspection)
      expect(tabs).to include("enclosed")
      expect(tabs.count).to eq(7) # Standard tabs plus enclosed
    end

    it "includes slide tab for units with slides" do
      unit = create(:unit)
      inspection.update!(unit: unit, has_slide: true)

      tabs = helper.inspection_tabs(inspection)
      expect(tabs).to include("slide")
      expect(tabs).to eq(%w[general user_height slide structure anchorage materials fan])
    end
  end

  describe "#inspection_actions" do
    let(:user) { create(:user) }
    let(:admin_user) { create(:user, email: "admin@example.com") }
    let(:inspection) { create(:inspection, user: user) }
    let(:complete_inspection) do
      inspection = create(:inspection, :complete, user: user)
      inspection
    end

    before do
      # Set up admin pattern
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
    end

    context "for non-complete inspections" do
      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "includes edit and delete actions" do
        actions = helper.inspection_actions(inspection)

        expect(actions).to include(
          hash_including(label: I18n.t("inspections.buttons.update"))
        )
        expect(actions).to include(
          hash_including(
            label: I18n.t("inspections.buttons.delete"),
            method: :delete,
            danger: true
          )
        )
      end
    end

    context "for complete inspections with regular user" do
      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "includes no actions for complete inspections" do
        actions = helper.inspection_actions(complete_inspection)

        expect(actions).not_to include(
          hash_including(label: I18n.t("inspections.buttons.update"))
        )
        expect(actions).not_to include(
          hash_including(label: I18n.t("inspections.buttons.delete"))
        )
        expect(actions).to be_empty
      end
    end

    context "for complete inspections with admin user" do
      before do
        allow(helper).to receive(:current_user).and_return(admin_user)
      end

      it "includes only delete action for complete inspections" do
        actions = helper.inspection_actions(complete_inspection)

        expect(actions).not_to include(
          hash_including(label: I18n.t("inspections.buttons.update"))
        )
        expect(actions).to include(
          hash_including(
            label: I18n.t("inspections.buttons.delete"),
            method: :delete,
            danger: true
          )
        )
      end
    end
  end
end
