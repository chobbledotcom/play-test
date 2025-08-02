require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  # Create anonymous controller for testing
  controller do
    # Public action for testing filters
    def index
      render plain: "OK"
    end

    # Action that skips login requirement
    skip_before_action :require_login, only: :public_action
    def public_action
      render plain: "Public"
    end
  end

  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  describe "private helper methods" do
    describe "#app_i18n" do
      it "translates with application namespace" do
        expect(controller.send(:app_i18n, :errors, :not_logged_in))
          .to eq(I18n.t("application.errors.not_logged_in"))
      end

      it "passes through interpolation arguments" do
        allow(I18n).to receive(:t).and_return("translated")
        controller.send(:app_i18n, :test, :key, name: "Test")
        expect(I18n).to have_received(:t).with("application.test.key", name: "Test")
      end
    end

    describe "#form_i18n" do
      it "translates with forms namespace" do
        expect(controller.send(:form_i18n, :session_new, "status.login_required"))
          .to eq(I18n.t("forms.session_new.status.login_required"))
      end
    end

    describe "#table_from_query" do
      it "extracts table from SELECT query" do
        sql = 'SELECT * FROM "users" WHERE id = 1'
        expect(controller.send(:table_from_query, sql)).to eq("users")
      end

      it "extracts table from INSERT query" do
        sql = 'INSERT INTO "inspections" (name) VALUES (?)'
        expect(controller.send(:table_from_query, sql)).to eq("inspections")
      end

      it "extracts table from UPDATE query" do
        sql = 'UPDATE "units" SET name = ? WHERE id = ?'
        expect(controller.send(:table_from_query, sql)).to eq("units")
      end

      it "extracts table from DELETE query" do
        sql = 'DELETE FROM "assessments" WHERE id = ?'
        expect(controller.send(:table_from_query, sql)).to eq("assessments")
      end

      it "handles queries without quotes" do
        sql = "SELECT * FROM users WHERE id = 1"
        expect(controller.send(:table_from_query, sql)).to eq("users")
      end

      it "returns nil for non-matching queries" do
        sql = "PRAGMA table_info(users)"
        expect(controller.send(:table_from_query, sql)).to be_nil
      end
    end

    describe "#seed_data_action?" do
      it "returns true for add_seeds action on users controller" do
        allow(controller).to receive(:controller_name).and_return("users")
        allow(controller).to receive(:action_name).and_return("add_seeds")
        expect(controller.send(:seed_data_action?)).to be true
      end

      it "returns true for delete_seeds action on users controller" do
        allow(controller).to receive(:controller_name).and_return("users")
        allow(controller).to receive(:action_name).and_return("delete_seeds")
        expect(controller.send(:seed_data_action?)).to be true
      end

      it "returns false for other actions on users controller" do
        allow(controller).to receive(:controller_name).and_return("users")
        allow(controller).to receive(:action_name).and_return("show")
        expect(controller.send(:seed_data_action?)).to be false
      end

      it "returns false for seed actions on other controllers" do
        allow(controller).to receive(:controller_name).and_return("inspections")
        allow(controller).to receive(:action_name).and_return("add_seeds")
        expect(controller.send(:seed_data_action?)).to be false
      end
    end

    describe "#processing_image_upload?" do
      before do
        routes.draw { post "index" => "anonymous#index" }
      end

      it "returns true for user logo upload" do
        allow(controller).to receive(:controller_name).and_return("users")
        allow(controller).to receive(:action_name).and_return("update_settings")
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(user: { logo: "file" })
        )
        expect(controller.send(:processing_image_upload?)).to be true
      end

      it "returns false for user update without logo" do
        allow(controller).to receive(:controller_name).and_return("users")
        allow(controller).to receive(:action_name).and_return("update_settings")
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(user: { name: "Test" })
        )
        expect(controller.send(:processing_image_upload?)).to be false
      end

      it "returns true for unit photo upload on create" do
        allow(controller).to receive(:controller_name).and_return("units")
        allow(controller).to receive(:action_name).and_return("create")
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(unit: { photo: "file" })
        )
        expect(controller.send(:processing_image_upload?)).to be true
      end

      it "returns true for unit photo upload on update" do
        allow(controller).to receive(:controller_name).and_return("units")
        allow(controller).to receive(:action_name).and_return("update")
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(unit: { photo: "file" })
        )
        expect(controller.send(:processing_image_upload?)).to be true
      end

      it "returns false for other controllers" do
        allow(controller).to receive(:controller_name).and_return("inspections")
        allow(controller).to receive(:action_name).and_return("create")
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(inspection: { photo: "file" })
        )
        expect(controller.send(:processing_image_upload?)).to be false
      end
    end

    describe "#impersonating?" do
      it "returns true when original_admin_id is in session" do
        session[:original_admin_id] = 123
        expect(controller.send(:impersonating?)).to be true
      end

      it "returns false when original_admin_id is not in session" do
        session[:original_admin_id] = nil
        expect(controller.send(:impersonating?)).to be false
      end
    end

    describe "#should_notify_error?" do
      let(:csrf_exception) { ActionController::InvalidAuthenticityToken.new }
      let(:other_exception) { StandardError.new("Something went wrong") }

      it "returns false for CSRF errors on sessions#create" do
        allow(controller).to receive(:controller_name).and_return("sessions")
        allow(controller).to receive(:action_name).and_return("create")
        expect(controller.send(:should_notify_error?, csrf_exception)).to be false
      end

      it "returns false for CSRF errors on users#create" do
        allow(controller).to receive(:controller_name).and_return("users")
        allow(controller).to receive(:action_name).and_return("create")
        expect(controller.send(:should_notify_error?, csrf_exception)).to be false
      end

      it "returns true for CSRF errors on other actions" do
        allow(controller).to receive(:controller_name).and_return("inspections")
        allow(controller).to receive(:action_name).and_return("create")
        expect(controller.send(:should_notify_error?, csrf_exception)).to be true
      end

      it "returns true for non-CSRF exceptions" do
        allow(controller).to receive(:controller_name).and_return("sessions")
        allow(controller).to receive(:action_name).and_return("create")
        expect(controller.send(:should_notify_error?, other_exception)).to be true
      end
    end
  end

  describe "authentication filters" do
    before do
      routes.draw do
        get "index" => "anonymous#index"
        get "public_action" => "anonymous#public_action"
      end
    end

    describe "#require_login" do
      context "when not logged in" do
        it "redirects to login path" do
          get :index
          expect(response).to redirect_to(login_path)
        end

        it "sets flash alert" do
          get :index
          expect(flash[:alert]).to eq(I18n.t("forms.session_new.status.login_required"))
        end
      end

      context "when logged in" do
        before do
          allow(controller).to receive(:current_user).and_return(user)
          allow(controller).to receive(:logged_in?).and_return(true)
        end

        it "allows access" do
          get :index
          expect(response).to have_http_status(:ok)
        end
      end

      it "can be skipped for specific actions" do
        get :public_action
        expect(response).to have_http_status(:ok)
      end
    end

    describe "#require_logged_out" do
      controller do
        skip_before_action :require_login
        before_action :require_logged_out

        def index
          render plain: "OK"
        end
      end

      context "when logged in" do
        before do
          allow(controller).to receive(:current_user).and_return(user)
          allow(controller).to receive(:logged_in?).and_return(true)
        end

        it "redirects to inspections path" do
          get :index
          expect(response).to redirect_to("/inspections")
        end

        it "sets flash alert" do
          get :index
          expect(flash[:alert]).to eq(I18n.t("forms.session_new.status.already_logged_in"))
        end
      end

      context "when not logged in" do
        it "allows access" do
          get :index
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe "#require_admin" do
      controller do
        skip_before_action :require_login
        before_action :require_admin

        def index
          render plain: "OK"
        end
      end

      context "when not logged in" do
        it "redirects to root path" do
          get :index
          expect(response).to redirect_to("/")
        end
      end

      context "when logged in as regular user" do
        before do
          allow(controller).to receive(:current_user).and_return(user)
          allow(controller).to receive(:logged_in?).and_return(true)
        end

        it "redirects to root path" do
          get :index
          expect(response).to redirect_to("/")
        end

        it "sets flash alert" do
          get :index
          expect(flash[:alert]).to eq(I18n.t("forms.session_new.status.admin_required"))
        end
      end

      context "when logged in as admin" do
        before do
          allow(controller).to receive(:current_user).and_return(admin)
          allow(controller).to receive(:logged_in?).and_return(true)
        end

        it "allows access" do
          get :index
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe "#update_last_active_at" do
      before do
        routes.draw { get "index" => "anonymous#index" }
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:logged_in?).and_return(true)
        user.update!(last_active_at: 1.hour.ago)
      end

      it "updates last_active_at for current user" do
        expect {
          get :index
        }.to change { user.reload.last_active_at }
      end

      it "does not update for non-User objects" do
        other_object = double("OtherObject", admin?: false)
        allow(controller).to receive(:current_user).and_return(other_object)
        expect {
          get :index
        }.not_to change { User.find(user.id).last_active_at }
      end
    end
  end

  describe "debug and performance monitoring" do
    describe "#admin_debug_enabled?" do
      it "returns true in development" do
        allow(Rails.env).to receive(:development?).and_return(true)
        expect(controller.send(:admin_debug_enabled?)).to be true
      end

      it "returns true for admin users" do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(controller).to receive(:current_user).and_return(admin)
        expect(controller.send(:admin_debug_enabled?)).to be true
      end

      it "returns true when impersonating" do
        allow(Rails.env).to receive(:development?).and_return(false)
        session[:original_admin_id] = 123
        expect(controller.send(:admin_debug_enabled?)).to be true
      end

      it "returns false for regular users in production" do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(controller).to receive(:current_user).and_return(user)
        expect(controller.send(:admin_debug_enabled?)).to be false
      end
    end

    describe "#should_check_query_limit?" do
      it "returns true when debug enabled and not seed action" do
        allow(controller).to receive(:admin_debug_enabled?).and_return(true)
        allow(controller).to receive(:seed_data_action?).and_return(false)
        expect(controller.send(:should_check_query_limit?)).to be true
      end

      it "returns false when debug disabled" do
        allow(controller).to receive(:admin_debug_enabled?).and_return(false)
        expect(controller.send(:should_check_query_limit?)).to be false
      end

      it "returns false for seed data actions" do
        allow(controller).to receive(:admin_debug_enabled?).and_return(true)
        allow(controller).to receive(:seed_data_action?).and_return(true)
        expect(controller.send(:should_check_query_limit?)).to be false
      end
    end

    describe "#count_queries_by_table" do
      it "counts queries by table name" do
        queries = [
          { sql: 'SELECT * FROM "users"' },
          { sql: 'SELECT * FROM "users" WHERE id = 1' },
          { sql: 'UPDATE "inspections" SET name = ?' },
          { sql: 'SELECT * FROM "units"' }
        ]
        controller.instance_variable_set(:@debug_sql_queries, queries)

        result = controller.send(:count_queries_by_table)
        expect(result).to eq({ "users" => 2, "inspections" => 1, "units" => 1 })
      end

      it "handles empty query list" do
        controller.instance_variable_set(:@debug_sql_queries, [])
        result = controller.send(:count_queries_by_table)
        expect(result).to eq({})
      end

      it "ignores queries without identifiable tables" do
        queries = [
          { sql: 'PRAGMA table_info(users)' },
          { sql: 'SELECT * FROM "users"' }
        ]
        controller.instance_variable_set(:@debug_sql_queries, queries)

        result = controller.send(:count_queries_by_table)
        expect(result).to eq({ "users" => 1 })
      end
    end
  end

  describe "error handling" do
    controller do
      skip_before_action :require_login
      
      def index
        raise StandardError, "Test error"
      end
    end

    before do
      routes.draw { get "index" => "anonymous#index" }
      allow(NtfyService).to receive(:notify)
    end

    context "in production" do
      before { allow(Rails.env).to receive(:production?).and_return(true) }

      it "notifies errors via NtfyService" do
        allow(controller).to receive(:current_user).and_return(user)
        get :index rescue nil
        expect(NtfyService).to have_received(:notify)
      end

      it "includes user email in notification" do
        allow(controller).to receive(:current_user).and_return(user)
        get :index rescue nil
        expect(NtfyService).to have_received(:notify) do |message|
          expect(message).to include(user.email)
        end
      end

      it "includes controller and action info" do
        allow(controller).to receive(:current_user).and_return(user)
        get :index rescue nil
        expect(NtfyService).to have_received(:notify) do |message|
          expect(message).to include("anonymous#index")
        end
      end

      it "handles not logged in users" do
        get :index rescue nil
        expect(NtfyService).to have_received(:notify) do |message|
          expect(message).to include(I18n.t("application.errors.not_logged_in"))
        end
      end

      it "does not notify for ignored CSRF exceptions" do
        allow(controller).to receive(:controller_name).and_return("sessions")
        allow(controller).to receive(:action_name).and_return("create")
        controller.define_singleton_method(:index) do
          raise ActionController::InvalidAuthenticityToken
        end

        get :index rescue nil
        expect(NtfyService).not_to have_received(:notify)
      end
    end

    context "in development" do
      before { allow(Rails.env).to receive(:production?).and_return(false) }

      it "does not notify errors" do
        get :index rescue nil
        expect(NtfyService).not_to have_received(:notify)
      end
    end
  end

  describe "helper methods exposed to views" do
    it "exposes admin_debug_enabled? as helper method" do
      expect(controller.class.helpers.methods).to include(:admin_debug_enabled?)
    end

    it "exposes impersonating? as helper method" do
      expect(controller.class.helpers.methods).to include(:impersonating?)
    end

    it "exposes debug_render_time as helper method" do
      expect(controller.class.helpers.methods).to include(:debug_render_time)
    end

    it "exposes debug_sql_queries as helper method" do
      expect(controller.class.helpers.methods).to include(:debug_sql_queries)
    end
  end

  describe "debug helper methods" do
    describe "#debug_render_time" do
      it "calculates time since debug start" do
        controller.instance_variable_set(:@debug_start_time, 1.second.ago)
        expect(controller.send(:debug_render_time)).to be_within(100).of(1000)
      end

      it "returns nil when no start time" do
        expect(controller.send(:debug_render_time)).to be_nil
      end
    end

    describe "#debug_sql_queries" do
      it "returns debug queries when set" do
        queries = [{ sql: "SELECT * FROM users" }]
        controller.instance_variable_set(:@debug_sql_queries, queries)
        expect(controller.send(:debug_sql_queries)).to eq(queries)
      end

      it "returns empty array when not set" do
        expect(controller.send(:debug_sql_queries)).to eq([])
      end
    end
  end
end