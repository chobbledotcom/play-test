require "rails_helper"

RSpec.describe "form/_assessment_status.html.erb", type: :view do
  let(:mock_assessment) { double("Assessment") }

  before do
    controller.params[:controller] = "inspections"
    controller.params[:tab] = "slide"
  end

  context "when assessment is not persisted" do
    before do
      allow(mock_assessment).to receive(:persisted?).and_return(false)
    end

    it "renders nothing" do
      render partial: "form/assessment_status", locals: {assessment: mock_assessment, i18n_base: "inspections.assessments.slide"}
      expect(rendered.strip).to be_empty
    end
  end

  context "when assessment is persisted" do
    before do
      allow(mock_assessment).to receive(:persisted?).and_return(true)
    end

    context "with height requirements" do
      before do
        allow(mock_assessment).to receive(:respond_to?) do |method|
          method == :meets_height_requirements?
        end
        allow(mock_assessment).to receive(:meets_height_requirements?).and_return(true)
      end

      it "displays height requirement status as pass" do
        render partial: "form/assessment_status", locals: {assessment: mock_assessment, i18n_base: "inspections.assessments.user_height"}

        expect(rendered).to include(I18n.t("inspections.assessments.user_height.sections.safety_status"))
        expect(rendered).to include(I18n.t("inspections.assessments.user_height.status.height_requirement"))
        expect(rendered).to include("text-success")
        expect(rendered).to include(I18n.t("inspections.assessments.user_height.status.pass"))
      end

      it "displays height requirement status as fail when false" do
        allow(mock_assessment).to receive(:meets_height_requirements?).and_return(false)

        render partial: "form/assessment_status", locals: {assessment: mock_assessment, i18n_base: "inspections.assessments.user_height"}

        expect(rendered).to include("text-danger")
        expect(rendered).to include(I18n.t("inspections.assessments.user_height.status.fail"))
      end
    end

    context "with runout requirements" do
      before do
        allow(mock_assessment).to receive(:respond_to?) do |method|
          method == :meets_runout_requirements?
        end
        allow(mock_assessment).to receive(:meets_runout_requirements?).and_return(true)
      end

      it "displays runout requirement status as pass" do
        render partial: "form/assessment_status", locals: {assessment: mock_assessment, i18n_base: "inspections.assessments.slide"}

        expect(rendered).to include(I18n.t("inspections.assessments.slide.status.runout_requirement"))
        expect(rendered).to include("text-success")
        expect(rendered).to include(I18n.t("inspections.assessments.slide.status.pass"))
      end

      it "displays runout requirement status as fail when false" do
        allow(mock_assessment).to receive(:meets_runout_requirements?).and_return(false)

        render partial: "form/assessment_status", locals: {assessment: mock_assessment, i18n_base: "inspections.assessments.slide"}

        expect(rendered).to include("text-danger")
        expect(rendered).to include(I18n.t("inspections.assessments.slide.status.fail"))
      end
    end

    context "with passed checks count" do
      before do
        allow(mock_assessment).to receive(:respond_to?) do |method|
          [:passed_checks_count, :safety_check_count].include?(method)
        end
        allow(mock_assessment).to receive(:passed_checks_count).and_return(5)
        allow(mock_assessment).to receive(:safety_check_count).and_return(10)
      end

      it "displays checks passed count" do
        render partial: "form/assessment_status", locals: {assessment: mock_assessment, i18n_base: "inspections.assessments.slide"}

        expect(rendered).to include(I18n.t("inspections.assessments.slide.status.checks_passed"))
        expect(rendered).to include("5 / 10")
      end
    end

    context "with completion percentage" do
      before do
        allow(mock_assessment).to receive(:respond_to?) do |method|
          method == :completion_percentage
        end
        allow(mock_assessment).to receive(:completion_percentage).and_return(75)
      end

      it "displays completion percentage" do
        render partial: "form/assessment_status", locals: {assessment: mock_assessment, i18n_base: "inspections.assessments.slide"}

        expect(rendered).to include(I18n.t("inspections.assessments.slide.status.completion"))
        expect(rendered).to include("75%")
      end
    end

    context "with custom i18n_base" do
      before do
        allow(mock_assessment).to receive(:respond_to?).and_return(false)
      end

      it "uses provided i18n_base for translations" do
        render partial: "form/assessment_status", locals: {
          assessment: mock_assessment,
          i18n_base: "custom.path"
        }

        expect(rendered).to include("translation missing: en.custom.path.sections.safety_status")
      end
    end

    context "with different controller" do
      before do
        controller.params[:controller] = "units"
        controller.params[:tab] = nil
        allow(mock_assessment).to receive(:respond_to?).and_return(false)
      end

      it "requires i18n_base to be provided" do
        render partial: "form/assessment_status", locals: {assessment: mock_assessment, i18n_base: "units"}

        expect(rendered).to include("translation missing: en.units.sections.safety_status")
      end
    end

    context "with all features" do
      before do
        allow(mock_assessment).to receive(:respond_to?).and_return(true)
        allow(mock_assessment).to receive(:meets_height_requirements?).and_return(true)
        allow(mock_assessment).to receive(:meets_runout_requirements?).and_return(false)
        allow(mock_assessment).to receive(:passed_checks_count).and_return(7)
        allow(mock_assessment).to receive(:safety_check_count).and_return(10)
        allow(mock_assessment).to receive(:completion_percentage).and_return(90)
      end

      it "displays all status information" do
        render partial: "form/assessment_status", locals: {assessment: mock_assessment, i18n_base: "inspections.assessments.slide"}

        expect(rendered).to include('<div class="assessment-status">')
        expect(rendered).to include("<h4>")
        expect(rendered).to include("text-success")
        expect(rendered).to include("text-danger")
        expect(rendered).to include("7 / 10")
        expect(rendered).to include("90%")
      end
    end
  end

  context "nil assessment" do
    it "handles nil assessment gracefully" do
      render partial: "form/assessment_status", locals: {assessment: nil, i18n_base: "inspections.assessments.slide"}
      expect(rendered.strip).to be_empty
    end
  end

  context "HTML structure" do
    before do
      allow(mock_assessment).to receive(:persisted?).and_return(true)
      allow(mock_assessment).to receive(:respond_to?) do |method|
        [:meets_runout_requirements?, :completion_percentage].include?(method)
      end
      allow(mock_assessment).to receive(:meets_runout_requirements?).and_return(true)
      allow(mock_assessment).to receive(:completion_percentage).and_return(50)
    end

    it "has proper semantic structure" do
      render partial: "form/assessment_status", locals: {assessment: mock_assessment, i18n_base: "inspections.assessments.slide"}

      expect(rendered).to include('<div class="assessment-status">')
      expect(rendered).to include("<h4>")
      expect(rendered).to include("<p>")
      expect(rendered).to include("<strong>")
      expect(rendered).to include("<span")
    end
  end
end
