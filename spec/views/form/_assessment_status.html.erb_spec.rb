require "rails_helper"

RSpec.describe "form/_assessment_status.html.erb", type: :view do
  
  let(:mock_assessment) { double("Assessment") }

  before do
    controller.params[:controller] = "inspections"
    controller.params[:tab] = "slide"
  end

  # Helper methods to reduce repetition
  def render_assessment_status(i18n_base: "forms.slide")
    render partial: "form/assessment_status", locals: {assessment: mock_assessment, i18n_base: i18n_base}
  end

  def expect_safety_header_present
    expect(rendered).to include('<div class="assessment-status">')
    expect(rendered).to include(I18n.t("shared.safety_status"))
  end

  def expect_status_displayed(status_key, pass: true)
    expect(rendered).to include(pass ? "text-success" : "text-danger")
    expect(rendered).to include(I18n.t(pass ? "shared.pass" : "shared.fail"))
  end

  def setup_assessment_with_method(method, return_value = true)
    allow(mock_assessment).to receive(:respond_to?) do |m|
      m == method
    end
    allow(mock_assessment).to receive(method).and_return(return_value)
  end

  context "when assessment is not persisted" do
    before do
      allow(mock_assessment).to receive(:persisted?).and_return(false)
      allow(mock_assessment).to receive(:respond_to?).and_return(false)
    end

    it "renders the status div with header only" do
      render_assessment_status(i18n_base: "inspections.assessments.slide")
      expect_safety_header_present
      expect(rendered).not_to include("text-success")
      expect(rendered).not_to include("text-danger")
    end
  end

  context "when assessment is persisted" do
    before do
      allow(mock_assessment).to receive(:persisted?).and_return(true)
    end

    context "with height requirements" do
      before do
        setup_assessment_with_method(:meets_height_requirements?)
      end

      it "displays height requirement status as pass" do
        render_assessment_status(i18n_base: "forms.tallest_user_height")
        
        expect_safety_header_present
        expect(rendered).to include(I18n.t("forms.tallest_user_height.status.height_requirement"))
        expect_status_displayed("height_requirement", pass: true)
      end

      it "displays height requirement status as fail when false" do
        setup_assessment_with_method(:meets_height_requirements?, false)
        
        render_assessment_status(i18n_base: "forms.tallest_user_height")
        
        expect_status_displayed("height_requirement", pass: false)
      end
    end

    context "with runout requirements" do
      before do
        setup_assessment_with_method(:meets_runout_requirements?)
      end

      it "displays runout requirement status as pass" do
        render_assessment_status
        
        expect(rendered).to include(I18n.t("forms.slide.status.runout_requirement"))
        expect_status_displayed("runout_requirement", pass: true)
      end

      it "displays runout requirement status as fail when false" do
        setup_assessment_with_method(:meets_runout_requirements?, false)
        
        render_assessment_status
        
        expect_status_displayed("runout_requirement", pass: false)
      end
    end

    context "with passed checks count" do
      before do
        allow(mock_assessment).to receive(:respond_to?) do |method|
          [:passed_checks_count, :pass_columns_count].include?(method)
        end
        allow(mock_assessment).to receive(:passed_checks_count).and_return(5)
        allow(mock_assessment).to receive(:pass_columns_count).and_return(10)
      end

      it "displays checks passed count" do
        render_assessment_status
        
        expect(rendered).to include(I18n.t("forms.slide.status.checks_passed"))
        expect(rendered.gsub(/\s+/, ' ')).to include("5 / 10")
      end
    end


    context "with custom i18n_base" do
      before do
        allow(mock_assessment).to receive(:respond_to?).and_return(false)
      end

      it "uses provided i18n_base for translations" do
        render_assessment_status(i18n_base: "custom.path")
        
        # The header uses shared.safety_status, not the i18n_base
        expect_safety_header_present
      end
    end

    context "with different controller" do
      before do
        controller.params[:controller] = "units"
        controller.params[:tab] = nil
        allow(mock_assessment).to receive(:respond_to?).and_return(false)
      end

      it "requires i18n_base to be provided" do
        render_assessment_status(i18n_base: "units")
        
        # The header uses shared.safety_status
        expect_safety_header_present
      end
    end

    context "with all features" do
      before do
        allow(mock_assessment).to receive(:respond_to?).and_return(true)
        allow(mock_assessment).to receive(:complete?).and_return(false)
        allow(mock_assessment).to receive(:incomplete_fields).and_return([
          { field: :test_field, label: "Test Field", type: :text }
        ])
        allow(mock_assessment).to receive(:meets_height_requirements?).and_return(true)
        allow(mock_assessment).to receive(:meets_runout_requirements?).and_return(false)
        allow(mock_assessment).to receive(:passed_checks_count).and_return(7)
        allow(mock_assessment).to receive(:pass_columns_count).and_return(10)
      end

      it "displays all status information" do
        render_assessment_status
        
        expect_safety_header_present
        expect(rendered).to include("<h4>")
        expect(rendered).to include("text-success")
        expect(rendered).to include("text-danger")
        expect(rendered.gsub(/\s+/, ' ')).to include("7 / 10")
      end
    end
  end

  context "nil assessment" do
    it "handles nil assessment gracefully" do
      render partial: "form/assessment_status", locals: {assessment: nil, i18n_base: "forms.slide"}
      # The partial still renders the wrapper div and header even with nil assessment
      expect_safety_header_present
    end
  end

  context "HTML structure" do
    before do
      allow(mock_assessment).to receive(:persisted?).and_return(true)
      allow(mock_assessment).to receive(:respond_to?) do |method|
        [:meets_runout_requirements?].include?(method)
      end
      allow(mock_assessment).to receive(:meets_runout_requirements?).and_return(true)
    end

    it "has proper semantic structure" do
      render_assessment_status
      
      expect_safety_header_present
      expect(rendered).to include("<h4>")
      expect(rendered).to include("<p>")
      expect(rendered).to include("<strong>")
      expect(rendered).to include("<span")
    end
  end
end
