require "rails_helper"
require Rails.root.join("db/seeds/seed_data")

RSpec.describe "Users", type: :request do
  # Helper to fill in multiple form fields at once
  def fill_in_form_fields(form_name, fields)
    fields.each do |field, value|
      fill_in_form(form_name, field, value) if value.present?
    end
  end

  # Helper to fill and submit a form in one go
  def fill_and_submit_form(form_name, fields)
    fill_in_form_fields(form_name, fields)
    submit_form(form_name)
  end
  describe "GET /signup" do
    it "returns http success" do
      visit "/signup"
      expect(page).to have_http_status(:success)
    end

    it "displays registration form" do
      visit "/signup"
      expect(page).to have_content(I18n.t("users.titles.register"))
      expect_form_fields_present("forms.user_new")
      expect(page).to have_button(I18n.t("users.buttons.register"))
    end
  end

  describe "POST /signup" do
    it "creates a user and redirects" do
      visit "/signup"

      user_data = SeedData.user_fields.merge(rpii_inspector_number: "RPII123")
      fill_and_submit_form(:user_new, user_data)

      expect(page).to have_current_path(root_path)
    end

    it "creates new users as inactive by default" do
      params = valid_user_params
      post "/users", params: params

      user = User.find_by(email: params[:user][:email])
      expect(user).to be_present
      expect(user.rpii_inspector_number).to eq("RPII123")
      expect(user.active_until).to eq(Date.current - 1.day)
      expect(user.is_active?).to be false
    end
  end

  describe "password change functionality" do
    let(:user) { create(:user) }

    context "when logged in as the user" do
      before do
        login_user_via_form(user)
      end

      it "allows access to change password page" do
        visit change_password_user_path(user)
        expect(page).to have_http_status(200)
        expect(page).to have_content(I18n.t("users.titles.change_password"))
      end

      it "updates the user's password when current password is correct" do
        visit change_password_user_path(user)
        fill_and_submit_form(:user_change_password, {
          current_password: I18n.t("test.password"),
          password: "newpassword",
          password_confirmation: "newpassword"
        })

        expect(page).to have_current_path(root_path)
        expect(user.reload.authenticate("newpassword")).to be_truthy
      end

      it "does not update the password when current password is incorrect" do
        visit change_password_user_path(user)
        fill_and_submit_form(:user_change_password, {
          current_password: I18n.t("test.invalid_password"),
          password: "newpassword",
          password_confirmation: "newpassword"
        })

        expect(page).to have_http_status(:unprocessable_entity)
        expect(user.reload.authenticate(I18n.t("test.password"))).to be_truthy
      end

      it "does not allow changing another user's password" do
        other_user = create(:user)

        visit change_password_user_path(other_user)
        expect(page).to have_current_path(root_path)
        expect(page).to have_content("You can only change your own password")
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        visit change_password_user_path(user)
        expect(page).to have_current_path(login_path)
      end
    end
  end

  describe "settings functionality" do
    let(:user) { create(:user) }
    let(:settings_params) { {user: {theme: "dark"}} }

    context "when logged in as the user" do
      before { login_as(user) }

      it "allows access to change settings page" do
        get change_settings_user_path(user)
        expect_access_allowed(response)
      end

      it "updates the user's settings" do
        patch update_settings_user_path(user), params: settings_params

        expect_redirect_with_notice(response, change_settings_user_path(user))
        expect(user.reload.theme).to eq("dark")
      end

      it "renders error when settings update fails" do
        allow_any_instance_of(User).to receive(:update).and_return(false)

        patch update_settings_user_path(user), params: settings_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not allow changing another user's settings" do
        other_user = create(:user)

        get change_settings_user_path(other_user)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("settings")

        patch update_settings_user_path(other_user), params: settings_params
        expect_access_denied(response)
      end
    end
  end

  def expect_access_allowed(response)
    expect(response).to have_http_status(200)
  end

  def expect_redirect_with_notice(response, path = users_path)
    expect(response).to redirect_to(path)
    expect(flash[:notice]).to be_present
  end

  def expect_access_denied(response)
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to be_present
  end

  def update_user_params(overrides = {})
    {
      user: {
        email: "updated@example.com",
        active_until: Date.current + 1.year
      }.merge(overrides)
    }
  end

  shared_examples "admin actions" do |allowed|
    it "#{allowed ? "allows" : "denies"} access to users index" do
      get users_path
      allowed ? expect_access_allowed(response) : expect_access_denied(response)
    end

    it "#{allowed ? "allows" : "denies"} editing a user" do
      get edit_user_path(target_user)
      allowed ? expect_access_allowed(response) : expect_access_denied(response)
    end

    it "#{allowed ? "allows" : "denies"} updating other users" do
      patch user_path(target_user), params: update_user_params

      if allowed
        expect_redirect_with_notice(response)
        expect(target_user.reload.email).to eq("updated@example.com")
      else
        expect_access_denied(response)
      end
    end

    it "#{allowed ? "allows" : "denies"} destroying other users" do
      delete user_path(target_user)

      if allowed
        expect_redirect_with_notice(response)
        expect { target_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
      else
        expect_access_denied(response)
      end
    end

    it "#{allowed ? "allows" : "denies"} impersonating other users" do
      post impersonate_user_path(target_user)

      if allowed
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("impersonating")
      else
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "admin functionality" do
    let(:admin) { create(:user, :admin) }
    let(:regular_user) { create(:user) }

    context "when logged in as admin" do
      before { login_as(admin) }
      let(:target_user) { regular_user }

      include_examples "admin actions", true

      it "renders error when user update fails" do
        patch user_path(regular_user), params: update_user_params(email: "")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when logged in as regular user" do
      before { login_as(regular_user) }
      let(:target_user) { admin }

      include_examples "admin actions", false
    end
  end

  def valid_user_params(overrides = {})
    user_data = SeedData.user_fields.merge(rpii_inspector_number: "RPII123")
    {user: user_data.merge(overrides)}
  end

  def expect_validation_error(field)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(assigns(:user).errors[field]).to be_present if assigns(:user)
  end

  describe "user creation" do
    it "renders new user form when validation fails" do
      post "/signup", params: valid_user_params(email: "")
      expect_validation_error(:email)
    end

    context "notifications" do
      before { allow(NtfyService).to receive(:notify) }

      it "sends notification in production environment" do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

        params = valid_user_params
        post "/signup", params: params

        expect(NtfyService).to have_received(:notify).with("new user: #{params[:user][:email]}")
      end

      it "does not send notification in non-production environment" do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))

        post "/signup", params: valid_user_params

        expect(NtfyService).not_to have_received(:notify)
      end
    end

    it "logs in user after successful creation" do
      params = valid_user_params
      post "/signup", params: params

      created_user = User.find_by(email: params[:user][:email])
      expect(session[:user_id]).to eq(created_user.id)
    end

    it "handles password confirmation mismatch" do
      post "/signup", params: valid_user_params(password_confirmation: "different")
      expect_validation_error(:password_confirmation)
    end

    it "handles duplicate email" do
      create(:user, email: "existing@example.com")

      post "/signup", params: valid_user_params(email: "existing@example.com")
      expect_validation_error(:email)
    end
  end

  describe "password change validation failures" do
    let(:user) { create(:user) }

    before { login_as(user) }

    it "renders error when new password validation fails" do
      password_params = {
        user: {
          current_password: I18n.t("test.password"),
          password: "short",
          password_confirmation: "short"
        }
      }

      patch update_password_user_path(user), params: password_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "admin user parameter handling" do
    let(:admin) { create(:user, :admin) }
    let(:company) { create(:inspector_company) }
    let(:regular_user) { create(:user) }

    before do
      login_as(admin)
    end

    it "allows admin to set additional fields when updating users" do
      patch user_path(regular_user), params: {
        user: {
          email: "updated@example.com",
          active_until: Date.current + 1.year,
          inspection_company_id: company.id,
          rpii_inspector_number: "RPII123"
        }
      }

      expect(response).to redirect_to(users_path)
      regular_user.reload
      expect(regular_user.email).to eq("updated@example.com")
      expect(regular_user.active_until).to eq(Date.current + 1.year)
      expect(regular_user.inspection_company_id).to eq(company.id)
      expect(regular_user.rpii_inspector_number).to eq("RPII123")
    end

    it "converts empty string to nil for inspection_company_id" do
      patch user_path(regular_user), params: {
        user: {
          inspection_company_id: "" # Empty string should become nil
        }
      }

      expect(response).to redirect_to(users_path)
      regular_user.reload
      expect(regular_user.inspection_company_id).to be_nil
    end
  end

  describe "impersonation with admin context" do
    let(:admin) { create(:user, :admin) }
    let(:target_user) { create(:user) }

    before do
      login_as(admin)
    end

    it "stores original admin ID in session when impersonating" do
      post impersonate_user_path(target_user)

      expect(session[:original_admin_id]).to eq(admin.id)
      expect(session[:user_id]).to eq(target_user.id)
    end

    it "handles impersonation when admin flag is present" do
      allow_any_instance_of(User).to receive(:admin?).and_return(true)

      post impersonate_user_path(target_user)

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include("impersonating")
      expect(flash[:notice]).to include(target_user.email)
    end
  end

  describe "non-admin user parameter restrictions" do
    let(:regular_user) { create(:user) }
    let(:company) { create(:inspector_company) }

    it "accepts RPII during registration but ignores admin-only fields" do
      params = valid_user_params(
        rpii_inspector_number: "RPII-REG-123",
        active_until: Date.current + 1.year,
        inspection_company_id: company.id
      )

      post "/signup", params: params

      created_user = User.find_by(email: params[:user][:email])
      expect(created_user).to be_present

      expect(created_user.rpii_inspector_number).to eq("RPII-REG-123")
      expect(created_user.active_until).to eq(Date.current - 1.day) # Default inactive
      expect(created_user.inspection_company_id).to be_nil
    end

    it "handles impersonation without existing admin session" do
      login_as(regular_user)

      allow_any_instance_of(User).to receive(:admin?).and_return(false)

      post impersonate_user_path(regular_user)

      expect(response).to redirect_to(root_path)
    end

    describe "updating settings with empty name" do
      before do
        login_as(regular_user)
      end

      it "allows updating settings even if name is empty" do
        regular_user.update_column(:name, nil)

        settings_attrs = {
          phone: "020 7946 0958",
          theme: "dark"
        }

        patch update_settings_user_path(regular_user), params: {user: settings_attrs}

        regular_user.reload
        expect(regular_user.phone).to eq("020 7946 0958")
        expect(regular_user.theme).to eq("dark")
        expect(regular_user.name).to be_nil
      end

      it "prevents users from changing their own name through settings" do
        original_name = regular_user.name

        settings_attrs = {
          name: "Hacker McHackface",
          phone: "020 7946 0958",
          theme: "dark"
        }

        patch update_settings_user_path(regular_user), params: {user: settings_attrs}

        regular_user.reload
        expect(regular_user.name).to eq(original_name)
        expect(regular_user.phone).to eq("020 7946 0958")
        expect(regular_user.theme).to eq("dark")
      end
    end
  end
end
