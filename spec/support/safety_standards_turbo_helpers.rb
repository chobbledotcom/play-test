module SafetyStandardsTurboHelpers
  def turbo_headers
    {"Accept" => "text/vnd.turbo-stream.html"}
  end
end

RSpec.configure do |config|
  config.include SafetyStandardsTurboHelpers, type: :request
end
