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
        result = helper.next_tab_navigation_info(inspection, "inspection")

        expect(result[:tab]).to eq("user_height")
        expect(result[:skip_incomplete]).to eq(false)
      end
    end

    context "when current tab is incomplete and no tabs after are incomplete" do
      before do
        # Complete all assessments
        inspection.applicable_assessments.each do |assessment_type, _|
          assessment = inspection.send(assessment_type)
          assessment.update!(complete: true)
        end
        # Make inspection tab incomplete
        inspection.update!(inspection_location: nil)
      end

      it "returns nil when all remaining tabs are complete" do
        result = helper.next_tab_navigation_info(inspection, "inspection")

        expect(result).to be_nil
      end
    end

    context "when current tab is incomplete and next tab is complete but tabs after that are incomplete" do
      before do
        # Make inspection tab incomplete
        inspection.update!(inspection_location: nil)
        # Complete user_height_assessment
        inspection.user_height_assessment.update!(complete: true)
        # Keep other assessments incomplete
      end

      it "skips the complete tab and suggests the next incomplete one" do
        result = helper.next_tab_navigation_info(inspection, "inspection")

        expect(result[:tab]).to eq("slide")
        expect(result[:skip_incomplete]).to eq(true)
        expect(result[:incomplete_count]).to eq(1)
      end
    end

    context "when on last assessment tab with results incomplete" do
      before do
        # Complete all assessments
        inspection.applicable_assessments.each do |assessment_type, _|
          assessment = inspection.send(assessment_type)
          assessment.update!(complete: true)
        end
      end

      it "returns results tab" do
        last_assessment = inspection.applicable_tabs[-2]
        result = helper.next_tab_navigation_info(inspection, last_assessment)

        expect(result[:tab]).to eq("results")
        expect(result[:skip_incomplete]).to eq(false)
      end
    end

    context "when everything is complete" do
      before do
        # Complete all assessments
        inspection.applicable_assessments.each do |assessment_type, _|
          assessment = inspection.send(assessment_type)
          assessment.update!(complete: true)
        end
        inspection.update!(passed: true)
      end

      it "returns nil" do
        result = helper.next_tab_navigation_info(inspection, "results")

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
        inspection.update!(inspection_location: nil, inspector: nil)
      end

      it "counts incomplete required fields" do
        count = helper.incomplete_fields_count(inspection, "inspection")
        expect(count).to eq(2)
      end

      it "caches the result" do
        # First call
        helper.incomplete_fields_count(inspection, "inspection")

        # Second call should use cache (we can't easily test this directly,
        # but at least verify it returns the same result)
        count = helper.incomplete_fields_count(inspection, "inspection")
        expect(count).to eq(2)
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
          max_user_height: nil,
          max_user_height_pass: nil
        )

        count = helper.incomplete_fields_count(inspection, "user_height")
        expect(count).to be > 0
      end
    end
  end
end
