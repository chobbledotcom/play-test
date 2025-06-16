require "rails_helper"

RSpec.describe "User Height Assessment Turbo Streams", type: :request do
  it_behaves_like "safety standards turbo streams", :user_height, {
    update_params: {tallest_user_height: 1.5},
    expected_content: [
      "User Height Requirements",
      "Containing walls must be at least 1.5m"
    ],
    minimal_params: {containing_wall_height: 2.0},
    calculated_values_test: {
      initial_values: {play_area_length: 5, play_area_width: 4},
      params: {play_area_length: 6, play_area_width: 5},
      expected_values: [20] # 6x5 = 30m², 30/1.5 = 20 users at 1000mm
    }
  }
end
