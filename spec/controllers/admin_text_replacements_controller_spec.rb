# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminTextReplacementsController, type: :controller do
  let(:admin) { create(:user, :admin) }

  before { allow(controller).to receive(:current_user).and_return(admin) }

  describe "GET #index" do
    it "renders the index" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #new" do
    it "renders the new form" do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates the replacement and redirects" do
        expect {
          post :create, params: {
            text_replacement: {i18n_key: "en.test.created", value: "Hello"}
          }
        }.to change(TextReplacement, :count).by(1)

        expect(response).to redirect_to(admin_text_replacements_path)
        expect(flash[:notice]).to eq(I18n.t("admin_text_replacements.messages.created"))
      end
    end

    context "with invalid params" do
      it "renders the new form again" do
        expect {
          post :create, params: {
            text_replacement: {i18n_key: "en.test.created", value: nil}
          }
        }.not_to change(TextReplacement, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET #edit" do
    let(:text_replacement) { create(:text_replacement) }

    it "renders the edit form" do
      get :edit, params: {id: text_replacement.id}
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH #update" do
    let(:text_replacement) { create(:text_replacement) }

    context "with valid params" do
      it "updates the replacement and redirects" do
        patch :update, params: {
          id: text_replacement.id,
          text_replacement: {value: "Updated value"}
        }

        expect(text_replacement.reload.value).to eq("Updated value")
        expect(response).to redirect_to(admin_text_replacements_path)
        expect(flash[:notice]).to eq(I18n.t("admin_text_replacements.messages.updated"))
      end
    end

    context "with invalid params" do
      it "renders the edit form again" do
        patch :update, params: {
          id: text_replacement.id,
          text_replacement: {value: nil}
        }

        expect(text_replacement.reload.value).to eq("Test replacement value")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:text_replacement) { create(:text_replacement) }

    it "destroys the replacement and redirects" do
      expect {
        delete :destroy, params: {id: text_replacement.id}
      }.to change(TextReplacement, :count).by(-1)

      expect(response).to redirect_to(admin_text_replacements_path)
      expect(flash[:notice]).to eq(I18n.t("admin_text_replacements.messages.destroyed"))
    end
  end

  describe "GET #i18n_value" do
    it "returns an empty value for a blank key" do
      get :i18n_value, params: {key: ""}
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("value" => "")
    end

    it "returns the translated value for an existing key" do
      get :i18n_value, params: {key: "en.admin.releases.title"}
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("value" => I18n.t("admin.releases.title"))
    end

    it "returns an empty value for a missing key" do
      get :i18n_value, params: {key: "en.no.such.key.exists"}
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("value" => "")
    end
  end
end
