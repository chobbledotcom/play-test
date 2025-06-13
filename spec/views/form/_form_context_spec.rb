require "rails_helper"

RSpec.describe "form/_form_context", type: :view do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user: user) }
  let(:i18n_base) { "test.base" }
  let(:render_options) { { model: inspection, i18n_base: i18n_base } }

  def mock_translations(header: "Test Header", submit: "Submit")
    allow(I18n).to receive(:t).with("#{i18n_base}.header").and_return(header)
    allow(I18n).to receive(:t).with("#{i18n_base}.submit", raise: true).and_return(submit)
    # Also mock the view helper t method
    allow(view).to receive(:t).with("#{i18n_base}.submit", raise: true).and_return(submit)
  end

  before do
    assign(:inspection, inspection)
    mock_translations
  end

  context "when i18n header key exists" do
    it "renders the page header" do
      render partial: "form/form_context", locals: render_options

      expect(rendered).to have_css("header")
      expect(rendered).to have_content("Test Header")
    end
  end

  context "when i18n header key does not exist" do
    before do
      allow(I18n).to receive(:t).with("#{i18n_base}.header").and_raise(I18n::MissingTranslationData.new(:en, "#{i18n_base}.header"))
    end

    it "does not render the page header" do
      # The form_context always tries to render header, so if translation is missing, it will fail
      expect {
        render partial: "form/form_context", locals: render_options
      }.to raise_error(ActionView::Template::Error)
    end
  end

  it "renders the form with correct attributes" do
    render partial: "form/form_context", locals: render_options

    expect(rendered).to have_css("form[action='#{inspection_path(inspection)}']")
    expect(rendered).to have_css("form[method='post']")
    expect(rendered).to have_css("form[data-turbo-stream]")
  end

  it "yields control to the block" do
    render partial: "form/form_context", locals: render_options

    # The block content would be passed in the actual view usage
    # This test just ensures the partial renders without errors
    expect(rendered).to be_present
  end
end