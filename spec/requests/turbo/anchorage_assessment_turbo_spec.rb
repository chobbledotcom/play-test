require "rails_helper"

RSpec.describe "Anchorage Assessment Turbo Streams", type: :request do
  it_behaves_like "safety standards turbo streams", :anchorage, {
    update_params: {num_low_anchors: 3, num_high_anchors: 2},
    expected_content: [
      "Anchor Requirements",
      "Total Anchors:",
      "5", # 3 + 2
      "Required Anchors:"
    ],
    minimal_params: {num_low_anchors: 1},
    calculated_values_test: {
      params: {num_low_anchors: 4, num_high_anchors: 3},
      expected_values: [7] # 4 + 3 = 7 total anchors
    }
  }
end
