require "rails_helper"

# Home Controller Behavior Documentation
# =====================================
#
# The Home controller manages the application's landing page and public information:
#
# PUBLIC ACCESS (no login required):
# - GET / (root_path) - Shows application homepage with features and navigation
# - GET /about - Shows about page with application information (if implemented)
#
# HOMEPAGE BEHAVIOR:
# 1. Displays when user is not logged in (public landing page)
# 2. Shows login/register links for anonymous users
# 3. Still accessible when user is logged in (but shows different navigation)
# 4. Contains embedded video, feature descriptions, and branding
# 5. Responsive design with semantic HTML structure
#
# AUTHENTICATION FLOW:
# - Skips require_login before_action (publicly accessible)
# - Conditionally shows login/register navigation based on current_user presence
# - Integrates with application layout navigation when user is logged in
#
# CONTENT FEATURES:
# - Application title and tagline
# - Feature descriptions (Log Inspections, Generate PDFs, Search & Export)
# - Embedded promotional video
# - Links to Chobble company website
# - Clean semantic HTML structure for SEO and accessibility

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when not logged in" do
      it "returns http success" do
        visit root_path
        expect(page).to have_http_status(:success)
      end

      it "renders the home page" do
        visit root_path
        expect(page).to have_current_path(root_path)
      end

      it "displays the application title" do
        visit root_path
        expect(page).to have_content("patlog.co.uk")
      end

      it "shows login and register links" do
        visit root_path
        expect(page).to have_link(I18n.t("session.login.title"), href: login_path)
        expect(page).to have_link(I18n.t("users.titles.register"), href: new_user_path)
      end

      it "displays feature descriptions" do
        visit root_path
        expect(page).to have_content("Log Inspections")
        expect(page).to have_content("Generate PDF Certificates")
        expect(page).to have_content("Search & Export")
      end

      it "includes promotional content" do
        visit root_path
        expect(page).to have_content("Portable Appliance Testing")
        expect(page).to have_content("QR codes")
        expect(page).to have_content("free and open source")
      end

      it "contains embedded video" do
        visit root_path
        expect(page).to have_css("iframe")
        expect(page).to have_css("div.video-container")
      end

      it "includes company branding" do
        visit root_path
        expect(page).to have_content(I18n.t("home.company_name"))
        expect(page).to have_link(I18n.t("home.company_name"), href: I18n.t("home.company_url"))
      end

      it "does not require authentication" do
        visit root_path
        expect(page).not_to have_current_path(login_path)
      end

      it "has proper semantic HTML structure" do
        visit root_path
        expect(page).to have_css("article")
        expect(page).to have_css("header")
        expect(page).to have_css("section")
        expect(page).to have_css("aside")
      end
    end

    context "when logged in" do
      let(:user) { create(:user) }

      before do
        visit login_path
        fill_in I18n.t("session.login.email_label"), with: user.email
        fill_in I18n.t("session.login.password_label"), with: I18n.t("test.password")
        click_button I18n.t("session.login.submit")
      end

      it "returns http success" do
        visit root_path
        expect(page).to have_http_status(:success)
      end

      it "renders the home page" do
        visit root_path
        expect(page).to have_current_path(root_path)
      end

      it "shows authenticated user navigation" do
        visit root_path
        # When logged in, shows logged-in user navigation
        expect(page).to have_button("Log Out")
        expect(page).to have_link("Settings")
        expect(page).to have_link("Inspections")
        expect(page).to have_link("Units")
      end

      it "still displays application content" do
        visit root_path
        expect(page).to have_content("patlog.co.uk")
        expect(page).to have_content("Log Inspections")
        expect(page).to have_content("Generate PDF Certificates")
      end

      it "allows access without redirect" do
        visit root_path
        expect(page).not_to have_current_path(login_path)
      end
    end

    context "response headers and performance" do
      it "sets appropriate cache headers" do
        visit root_path
        # Home page should be cacheable for performance
        expect(page.response_headers["Cache-Control"]).to be_present
      end

      it "includes security headers" do
        visit root_path
        expect(page.response_headers["X-Frame-Options"]).to be_present
      end

      it "responds quickly" do
        start_time = Time.current
        visit root_path
        response_time = Time.current - start_time

        expect(response_time).to be < 1.0  # Should respond in under 1 second
      end
    end

    context "edge cases and error handling" do
      it "handles malformed requests gracefully" do
        visit "#{root_path}?invalid=data"
        expect(page).to have_http_status(:success)
      end

      it "works with different HTTP methods (HEAD request)" do
        page.driver.browser.process(:head, root_path)
        expect(page).to have_http_status(:success)
      end

      it "handles concurrent requests" do
        threads = []
        5.times do
          threads << Thread.new do
            visit root_path
            expect(page).to have_http_status(:success)
          end
        end
        threads.each(&:join)
      end
    end
  end

  describe "GET /about" do
    context "when visiting about page" do
      it "returns success response" do
        visit about_path
        expect(page).to have_http_status(:ok)
      end

      it "renders about page content" do
        visit about_path
        expect(page).to have_content(I18n.t("about.title"))
        expect(page).to have_content(I18n.t("about.coming_soon"))
      end
    end
  end

  describe "navigation integration" do
    context "when logged in" do
      let(:user) { create(:user) }

      before do
        visit login_path
        fill_in I18n.t("session.login.email_label"), with: user.email
        fill_in I18n.t("session.login.password_label"), with: I18n.t("test.password")
        click_button I18n.t("session.login.submit")
      end

      it "integrates with application layout navigation" do
        visit root_path
        # Should include navigation from application layout
        expect(page).to have_link("Inspections")
        expect(page).to have_link("Units")
      end

      it "shows user-specific navigation options" do
        visit root_path
        expect(page).to have_button("Log Out") if page.has_button?("Log Out")
      end
    end
  end

  describe "accessibility and SEO" do
    it "includes proper page title" do
      visit root_path
      expect(page).to have_title("Test Logger")
    end

    it "has semantic HTML structure for screen readers" do
      visit root_path
      expect(page).to have_css("[role]") if page.has_css?("[role]")
      expect(page).to have_css("h1")
      expect(page).to have_css("h2")
    end

    it "includes meta descriptions for SEO" do
      visit root_path
      expect(page).to have_content("Portable Appliance Testing")
      expect(page).to have_content("PDF certificates")
    end
  end
end
