require "rails_helper"

RSpec.describe "Slide Assessment Turbo Streams", type: :request do
  it_behaves_like "safety standards turbo streams", :slide, {
    update_params: { slide_platform_height: 2.5 },
    expected_content: [
      "EN 14960:2019 Slide Requirements",
      "Walls must be at least 2.5m"
    ],
    minimal_params: { slide_wall_height: 3.0 },
    calculated_values_test: {
      params: { slide_platform_height: 3.0 },
      expected_values: [1.5] # 50% of 3.0m = 1.5m runout
    }
  }
end