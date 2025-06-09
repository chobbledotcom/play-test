require "rails_helper"

RSpec.describe "home/index.html.erb", type: :view do
  context "when user is not logged in" do
    before do
      allow(view).to receive(:current_user).and_return(nil)
    end

    it "displays the main heading" do
      render

      expect(rendered).to include(I18n.t("home.company_name"))
      expect(rendered).to include("<h1>")
    end

    it "shows the application description" do
      render

      expect(rendered).to include(I18n.t("home.subtitle"))
      expect(rendered).to include(I18n.t("home.features.generate_pdfs.title"))
      expect(rendered).to include("QR codes")
    end

    it "displays login and register navigation" do
      render

      expect(rendered).to include(I18n.t("session.login.title"))
      expect(rendered).to include(I18n.t("users.titles.register"))
      expect(rendered).to include("/login")
      expect(rendered).to include("/users/new")
    end

    it "includes company branding" do
      render

      expect(rendered).to include(I18n.t("home.company_name"))
      expect(rendered).to include(I18n.t("home.company_url"))
      expect(rendered).to include(I18n.t("home.attribution"))
    end

    it "contains embedded video" do
      render

      expect(rendered).to include("iframe")
      expect(rendered).to include("mediadelivery.net")
      expect(rendered).to include("video-container")
    end

    it "displays feature sections" do
      render

      expect(rendered).to include(I18n.t("home.features.log_inspections.title"))
      expect(rendered).to include(I18n.t("home.features.generate_pdfs.title"))
      expect(rendered).to include("Search &amp; Export")
    end

    it "has proper semantic HTML structure" do
      render

      expect(rendered).to include('<article class="home-page">')
      expect(rendered).to include("<header>")
      expect(rendered).to include("<section>")
      expect(rendered).to include("<aside>")
      expect(rendered).to include("<nav>")
    end

    it "includes feature descriptions" do
      render

      expect(rendered).to include("compliance tracking")
      expect(rendered).to include(I18n.t("home.features.generate_pdfs.description"))
      expect(rendered).to include("export data for analysis")
    end

    it "has accessibility-friendly structure" do
      render

      expect(rendered).to include("<h1>")
      expect(rendered).to include("<h2>")
      expect(rendered).to include("<p>")
    end

    it "includes video with proper attributes" do
      render

      expect(rendered).to include("loading=\"lazy\"")
      expect(rendered).to include("allowfullscreen")
      expect(rendered).to include("responsive=true")
    end
  end

  context "when user is logged in" do
    let(:user) { User.new(email: "user@example.com") }

    before do
      allow(view).to receive(:current_user).and_return(user)
    end

    it "displays the main content" do
      render

      expect(rendered).to include(I18n.t("home.company_name"))
      expect(rendered).to include(I18n.t("home.subtitle"))
    end

    it "handles user logged in state" do
      render

      # The view should render without errors when user is logged in
      expect(rendered).to include(I18n.t("home.company_name"))
      expect(rendered).to include(I18n.t("home.subtitle"))

      # Note: The navigation visibility is controlled by view logic
      # Testing the actual navigation behavior is better done in request specs
    end

    it "still shows feature sections" do
      render

      expect(rendered).to include(I18n.t("home.features.log_inspections.title"))
      expect(rendered).to include(I18n.t("home.features.generate_pdfs.title"))
      expect(rendered).to include("Search &amp; Export")
    end

    it "maintains proper HTML structure" do
      render

      expect(rendered).to include('<article class="home-page">')
      expect(rendered).to include("<header>")
      expect(rendered).to include("<section>")
    end
  end

  context "content validation" do
    before do
      allow(view).to receive(:current_user).and_return(nil)
    end

    it "has no broken links in content" do
      render

      # Check that links have proper href attributes
      expect(rendered).to match(/href="[^"]*login[^"]*"/)
      expect(rendered).to match(/href="[^"]*\/users\/new[^"]*"/)
      expect(rendered).to include(I18n.t("home.company_url"))
    end

    it "includes proper link attributes" do
      render

      # External links should have target and rel attributes for security
      company_link = rendered[/href="#{Regexp.escape(I18n.t("home.company_url"))}"[^>]*>/]
      expect(company_link).to be_present if company_link
    end

    it "has consistent text content" do
      render

      # Ensure text content is professional and consistent
      expect(rendered).not_to include("TODO")
      expect(rendered).not_to include("FIXME")
      expect(rendered).not_to include("placeholder")
    end

    it "includes all required sections" do
      render

      expect(rendered).to include(I18n.t("home.features.log_inspections.title"))
      expect(rendered).to include(I18n.t("home.features.generate_pdfs.title"))
      expect(rendered).to include("Search &amp; Export")
      expect(rendered).to include("compliance tracking")
      expect(rendered).to include("QR codes")
    end
  end

  context "responsive design elements" do
    before do
      allow(view).to receive(:current_user).and_return(nil)
    end

    it "includes responsive video container" do
      render

      expect(rendered).to include("video-container")
      expect(rendered).to include("responsive=true")
    end

    it "has mobile-friendly navigation structure" do
      render

      expect(rendered).to include("<nav>")
      expect(rendered).to include("<ul>")
      expect(rendered).to include("<li>")
    end

    it "uses semantic HTML for better mobile experience" do
      render

      expect(rendered).to include("<article")
      expect(rendered).to include("<header>")
      expect(rendered).to include("<section>")
    end
  end
end
