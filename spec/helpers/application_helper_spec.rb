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

    context "when current_user is present" do
      let(:user) { double("User") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "formats datetime with date only" do
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

      it "returns date only" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime.to_date)
        expect(result).to be_a(Date)
      end
    end

    context "when current_user is present" do
      let(:user) { double("User") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "returns date only" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime.to_date)
        expect(result).to be_a(Date)
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

  describe "#format_numeric_value" do
    context "with numeric values" do
      it "removes trailing zeros from decimal values" do
        expect(helper.format_numeric_value(5.0)).to eq("5")
        expect(helper.format_numeric_value(5.10)).to eq("5.1")
        expect(helper.format_numeric_value(5.012000)).to eq("5.012")
        expect(helper.format_numeric_value(-3.50)).to eq("-3.5")
      end

      it "preserves significant digits" do
        expect(helper.format_numeric_value(5.123)).to eq("5.123")
        expect(helper.format_numeric_value(0.5)).to eq("0.5")
        expect(helper.format_numeric_value(-0.25)).to eq("-0.25")
      end

      it "handles integers" do
        expect(helper.format_numeric_value(5)).to eq("5")
        expect(helper.format_numeric_value(-10)).to eq("-10")
        expect(helper.format_numeric_value(0)).to eq("0")
      end
    end

    context "with string values" do
      it "formats valid numeric strings" do
        expect(helper.format_numeric_value("5.0")).to eq("5")
        expect(helper.format_numeric_value("5.012000")).to eq("5.012")
        expect(helper.format_numeric_value("-3.50")).to eq("-3.5")
        expect(helper.format_numeric_value("0.5")).to eq("0.5")
      end

      it "handles integer strings" do
        expect(helper.format_numeric_value("5")).to eq("5")
        expect(helper.format_numeric_value("-10")).to eq("-10")
      end

      it "returns non-numeric strings unchanged" do
        expect(helper.format_numeric_value("not a number")).to eq("not a number")
        expect(helper.format_numeric_value("abc123")).to eq("abc123")
        expect(helper.format_numeric_value("")).to eq("")
      end
    end

    context "with nil and other types" do
      it "returns nil unchanged" do
        expect(helper.format_numeric_value(nil)).to eq(nil)
      end

      it "returns other types unchanged" do
        expect(helper.format_numeric_value(true)).to eq(true)
        expect(helper.format_numeric_value(false)).to eq(false)
        expect(helper.format_numeric_value([])).to eq([])
        expect(helper.format_numeric_value({})).to eq({})
      end
    end

    context "with edge cases" do
      it "handles very small numbers" do
        expect(helper.format_numeric_value(0.001)).to eq("0.001")
        expect(helper.format_numeric_value(0.0010)).to eq("0.001")
      end

      it "handles very large numbers" do
        expect(helper.format_numeric_value(1000000.0)).to eq("1000000")
        expect(helper.format_numeric_value(1000000.50)).to eq("1000000.5")
      end

      it "handles scientific notation conversion" do
        # Ruby may convert very large/small numbers to scientific notation
        # Our formatter should handle the string representation correctly
        large_num = 1e10
        expect(helper.format_numeric_value(large_num)).to be_a(String)
      end
    end
  end
end
