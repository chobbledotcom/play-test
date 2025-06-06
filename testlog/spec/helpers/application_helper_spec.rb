require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  let(:test_datetime) { Time.zone.parse("2025-06-06 14:30:45") }

  describe "#render_time" do
    context "when datetime is nil" do
      it "returns nil" do
        expect(helper.render_time(nil)).to be_nil
      end
    end

    context "when current_user is nil" do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it "uses default date format" do
        expect(helper.render_time(test_datetime)).to eq("Jun 06, 2025")
      end
    end

    context "when current_user has date time_display preference" do
      let(:user) { double("User", time_display: "date") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "formats datetime with date only" do
        expect(helper.render_time(test_datetime)).to eq("Jun 06, 2025")
      end
    end

    context "when current_user has time time_display preference" do
      let(:user) { double("User", time_display: "time") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "formats datetime with date and time" do
        expect(helper.render_time(test_datetime)).to eq("Jun 06, 2025 - 14:30")
      end
    end

    context "when current_user has invalid time_display preference" do
      let(:user) { double("User", time_display: "invalid") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "falls back to default date format" do
        expect(helper.render_time(test_datetime)).to eq("Jun 06, 2025")
      end
    end

    context "when current_user has nil time_display preference" do
      let(:user) { double("User", time_display: nil) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "falls back to default date format" do
        expect(helper.render_time(test_datetime)).to eq("Jun 06, 2025")
      end
    end
  end

  describe "#date_for_form" do
    context "when datetime is nil" do
      it "returns nil" do
        expect(helper.date_for_form(nil)).to be_nil
      end
    end

    context "when current_user is nil" do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it "returns full datetime" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime)
        expect(result).to be_a(Time)
      end
    end

    context "when current_user has date time_display preference" do
      let(:user) { double("User", time_display: "date") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "returns date only" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime.to_date)
        expect(result).to be_a(Date)
      end
    end

    context "when current_user has time time_display preference" do
      let(:user) { double("User", time_display: "time") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "returns full datetime" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime)
        expect(result).to be_a(Time)
      end
    end

    context "when current_user has invalid time_display preference" do
      let(:user) { double("User", time_display: "invalid") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "returns full datetime" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime)
        expect(result).to be_a(Time)
      end
    end
  end

  describe "#scrollable_table" do
    it "creates a scrollable table container with default options" do
      result = helper.scrollable_table do
        content_tag(:tr, "test content")
      end

      expect(result).to include('<div class="table-container">')
      expect(result).to include("<table>")
      expect(result).to include("<tr>test content</tr>")
      expect(result).to include("</table>")
      expect(result).to include("</div>")
    end

    it "creates a scrollable table container with custom HTML options" do
      result = helper.scrollable_table(class: "custom-table", id: "my-table") do
        content_tag(:tr, "test content")
      end

      expect(result).to include('<div class="table-container">')
      expect(result).to include('<table class="custom-table" id="my-table">')
      expect(result).to include("<tr>test content</tr>")
      expect(result).to include("</table>")
      expect(result).to include("</div>")
    end

    it "handles empty table content" do
      result = helper.scrollable_table do
        ""
      end

      expect(result).to include('<div class="table-container">')
      expect(result).to include("<table>")
      expect(result).to include("</table>")
      expect(result).to include("</div>")
    end

    it "passes through multiple HTML options" do
      result = helper.scrollable_table(
        :class => "table table-striped",
        :id => "data-table",
        "data-sortable" => "true"
      ) do
        content_tag(:thead, content_tag(:tr, content_tag(:th, "Header")))
      end

      expect(result).to include('class="table table-striped"')
      expect(result).to include('id="data-table"')
      expect(result).to include('data-sortable="true"')
      expect(result).to include("<th>Header</th>")
    end
  end

  describe "TIME_FORMATS constant" do
    it "has correct date format" do
      expect(ApplicationHelper::TIME_FORMATS["date"]).to eq("%b %d, %Y")
    end

    it "has correct time format" do
      expect(ApplicationHelper::TIME_FORMATS["time"]).to eq("%b %d, %Y - %H:%M")
    end
  end
end
