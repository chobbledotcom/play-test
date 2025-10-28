# typed: false

require "rails_helper"

RSpec.feature "JavaScript execution", js: true do
  scenario "executes JavaScript and updates DOM" do
    # Create a simple HTML page with JavaScript
    visit "/rails/info/routes"  # Using a built-in Rails page

    # Execute JavaScript to modify the page
    page.execute_script("document.body.style.backgroundColor = 'red'")

    # Verify JavaScript was executed by checking the computed style
    bg_color = page.evaluate_script("window.getComputedStyle(document.body).backgroundColor")
    expect(bg_color).to eq("rgb(255, 0, 0)")

    # Test JavaScript alert (Cuprite can handle these)
    accept_alert do
      page.execute_script("window.alert('Test alert')")
    end

    # Test that we can find elements after JS manipulation
    page.execute_script("document.body.innerHTML = '<h1 id=\"test\">JavaScript Works!</h1>'")
    expect(page).to have_css("#test", text: "JavaScript Works!")
  end
end
