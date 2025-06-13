require "rails_helper"

# Users Controller Behavior Documentation
# =====================================
#
# The Users controller manages user account operations with three distinct authorization levels:
#
# PUBLIC ACCESS (no login required):
# - GET /signup - Shows new user registration form
# - POST /signup - Creates new user account, auto-logs them in, sends production notifications
#
# USER ACCESS (must be logged in as the specific user):
# - GET /users/:id/change_password - Shows password change form (only for own account)
# - PATCH /users/:id/update_password - Updates password after verifying current password
# - GET /users/:id/change_settings - Shows settings form (only for own account)
# - PATCH /users/:id/update_settings - Updates user preferences like theme
#
# ADMIN ACCESS (must be logged in as admin):
# - GET /users - Lists all users with inspection counts and background job status
# - GET /users/:id/edit - Shows admin user edit form
# - PATCH /users/:id - Updates any user (admins can set inspection_limit)
# - DELETE /users/:id - Destroys user account
# - POST /users/:id/impersonate - Logs in as another user for support purposes
#
# AUTHORIZATION FLOW:
# 1. All actions except signup require login (ApplicationController#require_login)
# 2. Admin actions protected by require_admin before_action
# 3. Personal actions (password/settings) protected by require_correct_user
# 4. User creation auto-promotes first user to admin
# 5. Production environment sends notifications for new signups
#
# ERROR HANDLING:
# - Validation failures render forms with :unprocessable_entity status
# - Authorization failures redirect to root_path with danger flash
# - Password changes require current password verification
# - Settings only allow valid theme values ("light" or "dark")

RSpec.describe "Users", type: :request do
  describe "GET /signup" do
    it "returns http success" do
      visit "/signup"
      expect(page).to have_http_status(:success)
    end

    it "displays registration form" do
      visit "/signup"
      expect(page).to have_content(I18n.t("users.titles.register"))
      expect(page).to have_field(I18n.t("users.forms.email"))
      expect(page).to have_field(I18n.t("users.forms.name"))
      expect(page).to have_field(I18n.t("users.forms.rpii_inspector_number"))
      expect(page).to have_field(I18n.t("users.forms.password"))
      expect(page).to have_field(I18n.t("users.forms.password_confirmation"))
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

        # Verify password was changed
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

        # Verify password was not changed
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
      # Ensure admin? returns true
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
          # These admin-only fields should be ignored
          active_until: Date.current + 1.year,
          inspection_company_id: company.id
        }
      }

      created_user = User.find_by(email: "newuser@example.com")
      expect(created_user).to be_present
      # RPII should be accepted during registration
      expect(created_user.rpii_inspector_number).to eq("RPII-REG-123")
      # Admin-only fields should be ignored
      expect(created_user.active_until).to eq(Date.current - 1.day) # Default inactive
      expect(created_user.inspection_company_id).to be_nil
    end

    it "handles impersonation without existing admin session" do
      login_as(regular_user)
      # Simulate a non-admin user somehow reaching impersonate action
      # (this would normally be blocked by before_action, but testing the method itself)
      allow_any_instance_of(User).to receive(:admin?).and_return(false)

      post impersonate_user_path(regular_user)

      # Should be redirected due to admin requirement
      expect(response).to redirect_to(root_path)
    end

    describe "updating settings with empty name" do
      before do
        login_as(regular_user)
      end

      it "allows updating settings even if name is empty" do
        # Create user with empty name (bypassing validation)
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
