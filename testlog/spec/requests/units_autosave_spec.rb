require "rails_helper"

RSpec.describe "Units Auto-save", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user, name: "Original Name") }

  before do
    login_as user
  end

  describe "Auto-save functionality" do
    it "responds to PATCH requests with turbo stream accept header" do
      patch unit_path(unit),
        params: {
          unit: {
            name: "Updated Name",
            manufacturer: "Test Manufacturer"
          }
        },
        headers: {
          "Accept" => "text/vnd.turbo-stream.html",
          "X-CSRF-Token" => "test-token"
        }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end

    it "updates unit data via auto-save request" do
      expect {
        patch unit_path(unit),
          params: {
            unit: {
              name: "Auto-saved Name",
              width: 5.5,
              height: 3.2
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}
      }.to change { unit.reload.name }.from("Original Name").to("Auto-saved Name")
        .and change { unit.reload.width }.from(10.0).to(5.5)
        .and change { unit.reload.height }.from(3.0).to(3.2)
    end

    it "returns turbo stream with saved status on success" do
      patch unit_path(unit),
        params: {
          unit: {
            name: "Updated Name"
          }
        },
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response.body).to include("turbo-stream")
      expect(response.body).to include("autosave_status")
      expect(response.body).to include("saved")
    end

    it "handles validation errors gracefully" do
      patch unit_path(unit),
        params: {
          unit: {
            name: "", # Name is required
            manufacturer: ""
          }
        },
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:success)
      expect(response.body).to include("turbo-stream")
      expect(response.body).to include("autosave_status")
      expect(response.body).to include("error")

      # Unit should not be updated
      expect(unit.reload.name).to eq("Original Name")
    end

    it "updates dimensions correctly" do
      expect {
        patch unit_path(unit),
          params: {
            unit: {
              width: 12.0,
              length: 8.0,
              height: 4.5
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}
      }.to change { unit.reload.width }.from(10.0).to(12.0)
        .and change { unit.reload.length }.from(10.0).to(8.0)
        .and change { unit.reload.height }.from(3.0).to(4.5)
    end

    it "updates boolean fields correctly" do
      expect {
        patch unit_path(unit),
          params: {
            unit: {
              has_slide: true,
              is_totally_enclosed: true,
              permanent_roof: true
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}
      }.to change { unit.reload.has_slide }.from(false).to(true)
        .and change { unit.reload.is_totally_enclosed }.from(false).to(true)
        .and change { unit.reload.permanent_roof }.from(nil).to(true)
    end

    it "updates text fields correctly" do
      expect {
        patch unit_path(unit),
          params: {
            unit: {
              description: "Auto-saved description",
              notes: "Auto-saved notes",
              owner: "New Owner"
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}
      }.to change { unit.reload.description }.to("Auto-saved description")
        .and change { unit.reload.notes }.to("Auto-saved notes")
        .and change { unit.reload.owner }.to("New Owner")
    end

    it "handles rapid successive saves" do
      # Simulate rapid auto-save requests
      3.times do |i|
        patch unit_path(unit),
          params: {
            unit: {
              name: "Rapid Save #{i}"
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:success)
      end

      # Final value should be saved
      expect(unit.reload.name).to eq("Rapid Save 2")
    end

    it "preserves other HTTP format responses" do
      # Test that regular HTML updates still work
      patch unit_path(unit),
        params: {
          unit: {
            name: "Regular Update"
          }
        }

      expect(response).to have_http_status(:found) # Redirect
      expect(unit.reload.name).to eq("Regular Update")
    end
  end

  describe "Security" do
    it "only allows users to auto-save their own units" do
      other_user = create(:user)
      other_unit = create(:unit, user: other_user)

      patch unit_path(other_unit),
        params: {
          unit: {
            name: "Unauthorized Update"
          }
        },
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:found) # Redirect due to access denied
      expect(other_unit.reload.name).not_to eq("Unauthorized Update")
    end
  end
end
