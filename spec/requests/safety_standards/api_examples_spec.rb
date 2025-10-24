# typed: false

require "rails_helper"

RSpec.describe "Safety Standards API examples", type: :request do
  describe "API example parameters produce documented responses" do
    SafetyStandardsController::API_EXAMPLE_PARAMS.each do |type, params|
      context "#{type} calculation" do
        it "produces the exact response shown in API documentation" do
          # Make the API call with the documented example parameters
          post safety_standards_path,
            params: {calculation: params},
            headers: {"Accept" => "application/json"},
            as: :json

          expect(response).to have_http_status(:success)
          actual_response = JSON.parse(response.body, symbolize_names: true)

          # Get the documented example response
          example_response =
            SafetyStandardsController::API_EXAMPLE_RESPONSES[type]

          # Loop through all top-level keys in the example response
          example_response.each do |key, expected_value|
            expect(actual_response[key]).to eq(expected_value),
              "Mismatch for #{key} in #{type} calculation"
          end

          # Deep comparison of result object
          example_response[:result]&.each do |result_key, expected_result_value|
            actual_value = actual_response[:result][result_key]

            # Special handling for formula_breakdown array
            if result_key == :breakdown && expected_result_value.is_a?(Array)
              expect(actual_value).to be_an(Array)
              expect(actual_value.size).to eq(expected_result_value.size)

              # Compare each breakdown item
              expected_result_value.each_with_index do |expected_item, index|
                expect(actual_value[index]).to eq(expected_item),
                  "Formula breakdown mismatch at index #{index} for #{type}"
              end
            else
              expect(actual_value).to eq(expected_result_value),
                "Result mismatch for #{result_key} in #{type} calculation"
            end
          end
        end
      end
    end
  end

  describe "all calculation types use consistent response structure" do
    it "has required top-level keys for all calculations" do
      required_keys = [:passed, :status, :result]

      SafetyStandardsController::API_EXAMPLE_RESPONSES.each do |type, response|
        required_keys.each do |key|
          expect(response).to have_key(key),
            "#{type} response missing required key: #{key}"
        end
      end
    end

    it "all successful responses have passed=true and consistent status" do
      SafetyStandardsController::API_EXAMPLE_RESPONSES.each do |type, response|
        expect(response[:passed]).to eq(true),
          "#{type} response should have passed=true"
        expect(response[:status]).to eq("Calculation completed successfully"),
          "#{type} response should have consistent success status"
      end
    end
  end

  describe "parameter validation" do
    # Create invalid variations of each parameter set
    invalid_params_variations = {
      missing_type: ->(params) { params.except(:type) },
      nil_values: ->(params) { params.transform_values { nil } },
      negative_values: ->(params) {
        params.transform_values { |v| v.is_a?(Numeric) ? -v : v }
      },
      zero_values: ->(params) {
        params.transform_values { |v| v.is_a?(Numeric) ? 0 : v }
      }
    }

    SafetyStandardsController::API_EXAMPLE_PARAMS.each do |type, valid_params|
      context "#{type} calculation validation" do
        invalid_params_variations.each do |variation_name, transform|
          it "handles #{variation_name} appropriately" do
            invalid_params = transform.call(valid_params.dup)

            post safety_standards_path,
              params: {calculation: invalid_params},
              headers: {"Accept" => "application/json"},
              as: :json

            response_data = JSON.parse(response.body, symbolize_names: true)

            # Should either return an error or handle gracefully
            if variation_name == :missing_type
              expect(response_data[:passed]).to eq(false)
            elsif [:nil_values, :negative_values,
              :zero_values].include?(variation_name)
              # These should be handled according to business rules
              # Some calculations might accept zero, others might not
              expect(response_data).to have_key(:passed)
              expect(response_data).to have_key(:status)
            end
          end
        end
      end
    end
  end

  describe "curl commands produce expected results" do
    SafetyStandardsController::API_EXAMPLE_PARAMS.each do |type, params|
      it "curl command for #{type} would produce valid JSON" do
        # This simulates what the curl command would send
        curl_payload = {calculation: params}

        post safety_standards_path,
          params: curl_payload,
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          },
          as: :json

        expect(response).to have_http_status(:success)

        # Verify response is valid JSON
        response_data = JSON.parse(response.body)
        expect(response_data).to be_a(Hash)
        expect(response_data["passed"]).to be_in([true, false])
      end
    end
  end

  describe "response format consistency" do
    it "all error responses follow consistent format" do
      # Test with invalid type
      post safety_standards_path,
        params: {calculation: {type: "invalid_type"}},
        headers: {"Accept" => "application/json"},
        as: :json

      error_response = JSON.parse(response.body, symbolize_names: true)

      # Verify error response structure
      expect(error_response).to have_key(:passed)
      expect(error_response[:passed]).to eq(false)
      expect(error_response).to have_key(:status)
      expect(error_response).to have_key(:result)
    end

    it "all successful calculations return deterministic results" do
      # Run each calculation twice and verify same results
      SafetyStandardsController::API_EXAMPLE_PARAMS.each do |type, params|
        results = []

        2.times do
          post safety_standards_path,
            params: {calculation: params},
            headers: {"Accept" => "application/json"},
            as: :json

          results << JSON.parse(response.body, symbolize_names: true)
        end

        expect(results[0]).to eq(results[1]),
          "#{type} calculation should be deterministic"
      end
    end
  end
end
