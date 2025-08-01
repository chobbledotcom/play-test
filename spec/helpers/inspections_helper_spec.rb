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
      expect(tabs).to eq(%w[
        inspection
        user_height
        slide
        structure
        anchorage
        materials
        fan
        enclosed
        results
      ])
    end

    it "excludes enclosed tab when not needed" do
      inspection.update!(is_totally_enclosed: false)
      tabs = helper.inspection_tabs(inspection)
      expect(tabs).not_to include("enclosed")
    end

    it "excludes slide tab when not needed" do
      inspection.update!(has_slide: false)
      tabs = helper.inspection_tabs(inspection)
      expect(tabs).not_to include("slide")
    end
  end

  describe "#inspection_actions" do
    let(:user) { create(:user) }
    let(:admin_user) { create(:user, :admin) }
    let(:inspection) { create(:inspection, user: user) }
    let(:complete_inspection) do
      inspection = create(:inspection, :completed, user: user)
      inspection
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

      it "includes appropriate actions for complete inspections" do
        actions = helper.inspection_actions(complete_inspection)

        expect(actions).not_to include(
          hash_including(label: I18n.t("inspections.buttons.update"))
        )
        expect(actions).not_to include(
          hash_including(label: I18n.t("inspections.buttons.delete"))
        )
        expect(actions).to include(
          hash_including(label: I18n.t("inspections.buttons.switch_to_in_progress"))
        )
        expect(actions).to include(
          hash_including(label: I18n.t("inspections.buttons.log"))
        )
      end
    end

    context "for complete inspections with admin user" do
      before do
        allow(helper).to receive(:current_user).and_return(admin_user)
      end

      it "includes same actions as regular users for complete inspections" do
        actions = helper.inspection_actions(complete_inspection)

        expect(actions).not_to include(
          hash_including(label: I18n.t("inspections.buttons.update"))
        )
        expect(actions).not_to include(
          hash_including(label: I18n.t("inspections.buttons.delete"))
        )
        expect(actions).to include(
          hash_including(label: I18n.t("inspections.buttons.switch_to_in_progress"))
        )
        expect(actions).to include(
          hash_including(label: I18n.t("inspections.buttons.log"))
        )
      end
    end
  end

  describe "#inspection_result_badge" do
    let(:inspection) { build(:inspection) }

    context "when inspection passed is true" do
      before { inspection.passed = true }

      it "returns a pass badge with i18n text" do
        result = helper.inspection_result_badge(inspection)
        expect(result).to include("pass-badge")
        expect(result).to include(I18n.t("inspections.status.pass"))
      end
    end

    context "when inspection passed is false" do
      before { inspection.passed = false }

      it "returns a fail badge with i18n text" do
        result = helper.inspection_result_badge(inspection)
        expect(result).to include("fail-badge")
        expect(result).to include(I18n.t("inspections.status.fail"))
      end
    end

    context "when inspection passed is nil" do
      before { inspection.passed = nil }

      it "returns a pending badge with i18n text" do
        result = helper.inspection_result_badge(inspection)
        expect(result).to include("pending-badge")
        expect(result).to include(I18n.t("inspections.status.pending"))
      end
    end
  end

  describe "#next_tab_navigation_info" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }
    let(:inspection) { create(:inspection, unit: unit, user: user) }

    context "when there are incomplete tabs after current" do
      it "returns the first incomplete tab after current" do
        # The inspection tab is incomplete by default (missing width/length/height)
        # So skip_incomplete should be true
        result = helper.next_tab_navigation_info(inspection, "inspection")

        expect(result[:tab]).to eq("user_height")
        expect(result[:skip_incomplete]).to eq(true)
      end
    end

    context "when current tab is incomplete and no tabs after are incomplete" do
      before do
        # Use a completed inspection which has all assessments complete
        @completed_inspection = create(:inspection, :completed, user: user, unit: unit)
        # Make inspection tab incomplete by clearing some required fields
        @completed_inspection.update!(width: nil, length: nil)
      end

      it "returns nil when all remaining tabs are complete" do
        result = helper.next_tab_navigation_info(@completed_inspection, "inspection")

        expect(result).to be_nil
      end
    end

    context "when current tab is incomplete and next tab is complete but tabs after that are incomplete" do
      before do
        # Create a completed inspection first
        @test_inspection = create(:inspection, :completed, user: user, unit: unit)
        # Make inspection tab incomplete
        @test_inspection.update!(width: nil)
        # Ensure user_height is complete but slide is incomplete
        @test_inspection.slide_assessment&.update!(slide_platform_height: nil)
      end

      it "skips the complete tab and suggests the next incomplete one" do
        result = helper.next_tab_navigation_info(@test_inspection, "inspection")

        # Should skip the complete user_height tab and go to slide
        expect(result[:tab]).to eq("slide")
        expect(result[:skip_incomplete]).to eq(true)
        expect(result[:incomplete_count]).to eq(1)
      end
    end

    context "when on last assessment tab with results incomplete" do
      before do
        # Use a completed inspection which has all assessments complete
        @completed_inspection = create(:inspection, :completed, user: user, unit: unit)
        # Make results incomplete by clearing passed field
        @completed_inspection.update!(passed: nil)
      end

      it "returns results tab" do
        last_assessment = @completed_inspection.applicable_tabs[-2]
        result = helper.next_tab_navigation_info(@completed_inspection, last_assessment)

        expect(result[:tab]).to eq("results")
        expect(result[:skip_incomplete]).to eq(false)
      end
    end

    context "when everything is complete" do
      before do
        # Use a completed inspection which has all assessments complete
        @completed_inspection = create(:inspection, :completed, user: user, unit: unit)
        # Ensure passed is set (completed trait should already set this)
        @completed_inspection.update!(passed: true) if @completed_inspection.passed.nil?
      end

      it "returns nil" do
        result = helper.next_tab_navigation_info(@completed_inspection, "results")

        expect(result).to be_nil
      end
    end
  end

  describe "#incomplete_fields_count" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }
    let(:inspection) { create(:inspection, unit: unit, user: user) }

    context "for inspection tab" do
      before do
        inspection.update!(width: nil, length: nil)
      end

      it "counts incomplete required fields" do
        count = helper.incomplete_fields_count(inspection, "inspection")
        expect(count).to be >= 2
      end

      it "caches the result" do
        # First call
        helper.incomplete_fields_count(inspection, "inspection")

        # Second call should use cache (we can't easily test this directly,
        # but at least verify it returns the same result)
        count = helper.incomplete_fields_count(inspection, "inspection")
        expect(count).to be >= 2
      end
    end

    context "for results tab" do
      it "counts 1 when passed is nil" do
        inspection.update!(passed: nil)
        count = helper.incomplete_fields_count(inspection, "results")
        expect(count).to eq(1)
      end

      it "counts 0 when passed is set" do
        inspection.update!(passed: true)
        count = helper.incomplete_fields_count(inspection, "results")
        expect(count).to eq(0)
      end
    end

    context "for assessment tabs" do
      it "counts incomplete fields in the assessment" do
        assessment = inspection.user_height_assessment
        # Clear some required fields
        assessment.update!(
          # Clear fields that actually exist in user_height_assessment
          containing_wall_height: nil,
          tallest_user_height: nil
        )

        count = helper.incomplete_fields_count(inspection, "user_height")
        expect(count).to be > 0
      end
    end
  end
end
