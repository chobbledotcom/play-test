require "rails_helper"

RSpec.describe "Users", type: :request do
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
      fill_in I18n.t("forms.user_new.fields.email"), with: "newuser@example.com"
      fill_in I18n.t("forms.user_new.fields.name"), with: "New User"
      fill_in I18n.t("forms.user_new.fields.rpii_inspector_number"), with: "RPII123"
      fill_in I18n.t("forms.user_new.fields.password"), with: "password"
      fill_in I18n.t("forms.user_new.fields.password_confirmation"), with: "password"
      click_button I18n.t("users.buttons.register")

      expect(page).to have_current_path(root_path)
    end

    it "creates new users as inactive by default" do
      post "/users", params: {
        user: {
          email: "newuser@example.com",
          name: "New User",
          rpii_inspector_number: "RPII123",
          password: "password123",
          password_confirmation: "password123"
        }
      }

      user = User.find_by(email: "newuser@example.com")
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
        fill_in I18n.t("forms.user_change_password.fields.current_password"), with: I18n.t("test.password")
        fill_in I18n.t("forms.user_change_password.fields.password"), with: "newpassword"
        fill_in I18n.t("forms.user_change_password.fields.password_confirmation"), with: "newpassword"
        click_button I18n.t("users.buttons.update_password")

        expect(page).to have_current_path(root_path)


        user.reload
        expect(user.authenticate("newpassword")).to be_truthy
      end

      it "does not update the password when current password is incorrect" do
        visit change_password_user_path(user)
        fill_in I18n.t("forms.user_change_password.fields.current_password"), with: I18n.t("test.invalid_password")
        fill_in I18n.t("forms.user_change_password.fields.password"), with: "newpassword"
        fill_in I18n.t("forms.user_change_password.fields.password_confirmation"), with: "newpassword"
        click_button I18n.t("users.buttons.update_password")

        expect(page).to have_http_status(:unprocessable_entity)


        user.reload
        expect(user.authenticate(I18n.t("test.password"))).to be_truthy
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

    context "when logged in as the user" do
      before do
        login_as(user)
      end

      it "allows access to change settings page" do
        get change_settings_user_path(user)
        expect(response).to have_http_status(200)
      end

      it "updates the user's settings" do
        patch update_settings_user_path(user), params: {
          user: {
            theme: "dark"
          }
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to be_present

        user.reload
        expect(user.theme).to eq("dark")
      end

      it "renders error when settings update fails" do
        allow_any_instance_of(User).to receive(:update).and_return(false)

        patch update_settings_user_path(user), params: {
          user: {
            theme: "invalid"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not allow changing another user's settings" do
        other_user = create(:user)

        get change_settings_user_path(other_user)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("settings")

        patch update_settings_user_path(other_user), params: {
          user: {
            theme: "dark"
          }
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "admin functionality" do
    let(:admin) { create(:user, :admin) }
    let(:regular_user) { create(:user) }

    context "when logged in as admin" do
      before do
        login_as(admin)
      end

      it "allows access to users index" do
        get users_path
        expect(response).to have_http_status(200)
      end

      it "allows editing a user" do
        get edit_user_path(regular_user)
        expect(response).to have_http_status(200)
      end

      it "updates a user successfully" do
        patch user_path(regular_user), params: {
          user: {
            email: "updated@example.com",
            active_until: Date.current + 1.year
          }
        }

        expect(response).to redirect_to(users_path)
        expect(flash[:notice]).to be_present

        regular_user.reload
        expect(regular_user.email).to eq("updated@example.com")
        expect(regular_user.active_until).to eq(Date.current + 1.year)
      end

      it "renders error when user update fails" do
        patch user_path(regular_user), params: {
          user: {
            email: "" # Invalid email
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "destroys a user" do
        delete user_path(regular_user)

        expect(response).to redirect_to(users_path)
        expect(flash[:notice]).to be_present
        expect { regular_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "allows impersonating a user" do
        post impersonate_user_path(regular_user)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("impersonating")
      end
    end

    context "when logged in as regular user" do
      before do
        login_as(regular_user)
      end

      it "denies access to users index" do
        get users_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      it "denies access to edit other users" do
        get edit_user_path(admin)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      it "denies updating other users" do
        patch user_path(admin), params: {
          user: {
            email: "hacked@example.com"
          }
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      it "denies destroying other users" do
        delete user_path(admin)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      it "denies impersonating other users" do
        post impersonate_user_path(admin)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "user creation" do
    it "renders new user form when validation fails" do
      post "/signup", params: {
        user: {
          email: "", # Invalid email
          password: "password",
          password_confirmation: "password"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "sends notification in production environment" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      allow(NtfyService).to receive(:notify)

      post "/signup", params: {
        user: {
          email: "newuser@example.com",
          name: "New User",
          rpii_inspector_number: "RPII123",
          password: "password",
          password_confirmation: "password"
        }
      }

      expect(NtfyService).to have_received(:notify).with("new user: newuser@example.com")
    end

    it "does not send notification in non-production environment" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      allow(NtfyService).to receive(:notify)

      post "/signup", params: {
        user: {
          email: "newuser@example.com",
          name: "New User",
          rpii_inspector_number: "RPII123",
          password: "password",
          password_confirmation: "password"
        }
      }

      expect(NtfyService).not_to have_received(:notify)
    end

    it "logs in user after successful creation" do
      post "/signup", params: {
        user: {
          email: "newuser@example.com",
          name: "New User",
          rpii_inspector_number: "RPII123",
          password: "password",
          password_confirmation: "password"
        }
      }

      created_user = User.find_by(email: "newuser@example.com")
      expect(session[:user_id]).to eq(created_user.id)
    end

    it "handles password confirmation mismatch" do
      post "/signup", params: {
        user: {
          email: "newuser@example.com",
          password: "password",
          password_confirmation: "different"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(assigns(:user).errors[:password_confirmation]).to be_present
    end

    it "handles duplicate email" do
      create(:user, email: "existing@example.com")

      post "/signup", params: {
        user: {
          email: "existing@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(assigns(:user).errors[:email]).to be_present
    end
  end

  describe "password change validation failures" do
    let(:user) { create(:user) }

    before do
      login_as(user)
    end

    it "renders error when new password validation fails" do
      patch update_password_user_path(user), params: {
        user: {
          current_password: I18n.t("test.password"),
          password: "short", # Too short
          password_confirmation: "short"
        }
      }

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
      post "/signup", params: {
        user: {
          email: "newuser@example.com",
          name: "New User",
          rpii_inspector_number: "RPII-REG-123",
          password: "password123",
          password_confirmation: "password123",

          active_until: Date.current + 1.year,
          inspection_company_id: company.id
        }
      }

      created_user = User.find_by(email: "newuser@example.com")
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
