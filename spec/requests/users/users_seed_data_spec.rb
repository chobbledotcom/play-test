require "rails_helper"

RSpec.describe "Users Seed Data Management", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:test_user) { create(:user) }

  describe "POST /users/:id/add_seeds" do
    context "as admin" do
      before { login_as(admin_user) }

      context "when user has no seed data" do
        it "adds seed data and redirects with success message" do
          post add_seeds_user_path(test_user)

          expect(response).to redirect_to(edit_user_path(test_user))
          follow_redirect!
          expect(response.body).to include(I18n.t("users.messages.seeds_added"))
          expect(test_user.reload.has_seed_data?).to be true
        end
      end

      context "when user already has seed data" do
        before { create(:unit, user: test_user, is_seed: true) }

        it "does not add more data and shows failure message" do
          initial_count = test_user.units.count

          post add_seeds_user_path(test_user)

          expect(response).to redirect_to(edit_user_path(test_user))
          follow_redirect!
          expect(response.body)
            .to include(I18n.t("users.messages.seeds_failed"))
          expect(test_user.units.count).to eq(initial_count)
        end
      end
    end

    context "as non-admin" do
      before { login_as(regular_user) }

      it "redirects to root with error" do
        post add_seeds_user_path(test_user)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body)
          .to include(I18n.t("forms.session_new.status.admin_required"))
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        post add_seeds_user_path(test_user)

        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "DELETE /users/:id/delete_seeds" do
    context "as admin" do
      before do
        login_as(admin_user)
        SeedDataService.add_seeds_for_user(test_user, unit_count: 1, inspection_count: 1)
      end

      it "deletes seed data and redirects with success message" do
        expect(test_user.has_seed_data?).to be true

        delete delete_seeds_user_path(test_user)

        expect(response).to redirect_to(edit_user_path(test_user))
        follow_redirect!
        expect(response.body).to include(I18n.t("users.messages.seeds_deleted"))
        expect(test_user.reload.has_seed_data?).to be false
      end
    end

    context "as non-admin" do
      before do
        login_as(regular_user)
        SeedDataService.add_seeds_for_user(test_user, unit_count: 1, inspection_count: 1)
      end

      it "redirects to root with error" do
        delete delete_seeds_user_path(test_user)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body)
          .to include(I18n.t("forms.session_new.status.admin_required"))
        expect(test_user.reload.has_seed_data?).to be true
      end
    end
  end
end
