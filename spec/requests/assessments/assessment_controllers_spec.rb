# typed: false

require "rails_helper"

RSpec.describe "Assessment Controllers", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before do
    login_as(user)
  end

  describe "Structure Assessment" do
    it "updates structure assessment" do
      # Create assessment by visiting inspection
      get edit_inspection_path(inspection)
      assessment = inspection.structure_assessment

      patch inspection_structure_assessment_path(inspection), params: {
        assessment.class.model_name.param_key => {
          seam_integrity_pass: true,
          stitch_length_pass: true
        }
      }

      expect(response).to redirect_to(inspection_path(inspection))
      inspection.reload
      expect(inspection.structure_assessment.seam_integrity_pass).to be true
      expect(inspection.structure_assessment.stitch_length_pass).to be true
    end
  end

  describe "User Height Assessment" do
    it "updates user height assessment" do
      # Create assessment by visiting inspection
      get edit_inspection_path(inspection)
      assessment = inspection.user_height_assessment

      patch inspection_user_height_assessment_path(inspection), params: {
        assessment.class.model_name.param_key => {
          containing_wall_height: 1.8,
          users_at_1500mm: 25
        }
      }

      expect(response).to redirect_to(inspection_path(inspection))
      inspection.reload
      wall_height = inspection.user_height_assessment.containing_wall_height
      expect(wall_height).to eq(1.8)
      expect(inspection.user_height_assessment.users_at_1500mm).to eq(25)
    end
  end

  describe "Materials Assessment" do
    it "updates materials assessment" do
      # Create assessment by visiting inspection
      get edit_inspection_path(inspection)
      assessment = inspection.materials_assessment

      patch inspection_materials_assessment_path(inspection), params: {
        assessment.class.model_name.param_key => {
          ropes: 30,
          fabric_strength_pass: true
        }
      }

      expect(response).to redirect_to(inspection_path(inspection))
      inspection.reload
      expect(inspection.materials_assessment.ropes).to eq(30)
      expect(inspection.materials_assessment.fabric_strength_pass).to be true
    end
  end

  describe "Slide Assessment" do
    it "updates slide assessment" do
      # Create assessment by visiting inspection
      get edit_inspection_path(inspection)
      assessment = inspection.slide_assessment

      patch inspection_slide_assessment_path(inspection), params: {
        assessment.class.model_name.param_key => {
          slide_platform_height: 2.5,
          clamber_netting_pass: :pass
        }
      }

      expect(response).to redirect_to(inspection_path(inspection))
      inspection.reload
      expect(inspection.slide_assessment.slide_platform_height).to eq(2.5)
      expect(inspection.slide_assessment.clamber_netting_pass).to eq "pass"
    end
  end
end
