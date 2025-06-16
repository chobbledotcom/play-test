RSpec.shared_examples "safety standards turbo streams" do |assessment_type, test_params|
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user:) }

  before { login_as(user) }

  describe "PATCH /inspections/:inspection_id/#{assessment_type}_assessment" do
    it "updates safety standards via turbo stream" do
      update_assessment_via_turbo(inspection, assessment_type, test_params[:update_params])

      expect_safety_standards_turbo_stream(response, assessment_type)

      # Check for expected content (not raw i18n keys)
      test_params[:expected_content]&.each do |content|
        expect(response.body).to include(content)
      end
    end

    it "includes safety results frame in turbo response" do
      update_assessment_via_turbo(inspection, assessment_type, test_params[:minimal_params])

      expect(response.body).to include("#{assessment_type}_safety_results")
    end

    if test_params[:calculated_values_test]
      it "updates calculated values dynamically" do
        # Set initial values if needed
        if test_params[:initial_values]
          inspection.send("#{assessment_type}_assessment").update!(test_params[:initial_values])
        end

        update_assessment_via_turbo(inspection, assessment_type, test_params[:calculated_values_test][:params])

        test_params[:calculated_values_test][:expected_values].each do |value|
          expect(response.body).to include(value.to_s)
        end
      end
    end
  end
end
