require "capybara/cuprite"

# Configure Cuprite for JavaScript testing
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app,
    window_size: [1200, 800],
    browser_options: {
      "no-sandbox": nil,
      "disable-dev-shm-usage": nil
    },
    headless: true,
    timeout: 10)
end

# Only use Cuprite for tests tagged with js: true
Capybara.javascript_driver = :cuprite
