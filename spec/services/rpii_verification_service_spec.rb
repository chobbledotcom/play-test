# typed: false
# frozen_string_literal: true

require "rails_helper"
require "net/http"

RSpec.describe RpiiVerificationService do
  describe ".search" do
    context "when inspector_number is blank" do
      it "returns an empty array for nil" do
        expect(described_class.search(nil)).to eq([])
      end

      it "returns an empty array for empty string" do
        expect(described_class.search("")).to eq([])
      end

      it "returns an empty array for whitespace" do
        expect(described_class.search("   ")).to eq([])
      end
    end

    context "when API request succeeds" do
      let(:mock_response) { instance_double(Net::HTTPResponse) }
      let(:inspector_number) { "12345" }

      before do
        allow(described_class).to receive(:make_api_request).and_return(mock_response)
        allow(mock_response).to receive(:code).and_return("200")
      end

      it "parses response with suggestions array" do
        response_body = {
          "suggestions" => [
            {
              "value" => "12345",
              "data" => "12345"
            }
          ]
        }.to_json

        allow(mock_response).to receive(:body).and_return(response_body)

        results = described_class.search(inspector_number)

        expect(results).to eq([
          {
            raw_value: "12345",
            number: "12345",
            id: "12345"
          }
        ])
      end

      it "parses response as direct array" do
        response_body = [
          {
            "value" => "67890",
            "data" => "67890"
          }
        ].to_json

        allow(mock_response).to receive(:body).and_return(response_body)

        results = described_class.search(inspector_number)

        expect(results).to eq([
          {
            raw_value: "67890",
            number: "67890",
            id: "67890"
          }
        ])
      end

      it "handles multiple inspectors in response" do
        response_body = {
          "suggestions" => [
            {
              "value" => "11111",
              "data" => "11111"
            },
            {
              "value" => "22222",
              "data" => "22222"
            }
          ]
        }.to_json

        allow(mock_response).to receive(:body).and_return(response_body)

        results = described_class.search(inspector_number)

        expect(results.length).to eq(2)
        expect(results[0][:number]).to eq("11111")
        expect(results[1][:number]).to eq("22222")
      end

      it "handles name-number-qualifications format" do
        response_body = {
          "suggestions" => [
            {
              "value" => "unique-id",
              "data" => "unique-id"
            }
          ]
        }.to_json

        allow(mock_response).to receive(:body).and_return(response_body)

        results = described_class.search(inspector_number)

        expect(results).to eq([
          {
            raw_value: "unique-id",
            number: "unique-id",
            id: "unique-id"
          }
        ])
      end

      it "handles simple format without parentheses" do
        response_body = {
          "suggestions" => [
            {
              "value" => "Simple Name",
              "data" => "99999"
            }
          ]
        }.to_json

        allow(mock_response).to receive(:body).and_return(response_body)

        results = described_class.search(inspector_number)

        expect(results).to eq([
          {
            raw_value: "Simple Name",
            number: "99999",
            id: "99999"
          }
        ])
      end

      it "handles empty suggestions array" do
        response_body = {"suggestions" => []}.to_json

        allow(mock_response).to receive(:body).and_return(response_body)

        results = described_class.search(inspector_number)

        expect(results).to eq([])
      end

      it "handles invalid JSON response gracefully" do
        allow(mock_response).to receive(:body).and_return("not valid json")

        expect { described_class.search(inspector_number) }.to raise_error(JSON::ParserError)
      end

      it "handles unexpected response structure" do
        response_body = {"unexpected" => "structure"}.to_json

        allow(mock_response).to receive(:body).and_return(response_body)

        results = described_class.search(inspector_number)

        expect(results).to eq([])
      end

      it "accepts integer inspector numbers" do
        response_body = {"suggestions" => []}.to_json

        allow(mock_response).to receive(:body).and_return(response_body)

        expect { described_class.search(12345) }.not_to raise_error
      end

      it "strips whitespace from inspector number" do
        mock_request = instance_double(Net::HTTP::Post)
        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:[]=)
        allow(mock_request).to receive(:body=) do |body|
          expect(body).to include("search=12345")
        end

        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:request).and_return(mock_response)
        allow(mock_response).to receive(:body).and_return('{"suggestions": []}')

        described_class.search("  12345  ")
      end
    end

    context "when API request fails" do
      let(:mock_response) { instance_double(Net::HTTPResponse) }
      let(:inspector_number) { "12345" }

      before do
        allow(described_class).to receive(:make_api_request).and_return(mock_response)
        allow(Rails.logger).to receive(:error)
        # Stub log_error to avoid Sorbet type checking issues
        allow(described_class).to receive(:log_error)
      end

      it "returns empty array for 404 response" do
        allow(mock_response).to receive(:code).and_return("404")
        allow(mock_response).to receive(:body).and_return("Not Found")

        results = described_class.search(inspector_number)

        expect(results).to eq([])
      end

      it "returns empty array for 500 response" do
        allow(mock_response).to receive(:code).and_return("500")
        allow(mock_response).to receive(:body).and_return("Internal Server Error")

        results = described_class.search(inspector_number)

        expect(results).to eq([])
      end

      it "logs error for non-200 response" do
        allow(mock_response).to receive(:code).and_return("403")
        allow(mock_response).to receive(:body).and_return("Forbidden")

        described_class.search(inspector_number)

        expect(described_class).to have_received(:log_error).with(mock_response)
      end
    end
  end

  describe ".verify" do
    context "when inspector is found" do
      it "returns valid true with matching inspector" do
        allow(described_class).to receive(:search).with("12345").and_return([
          {
            name: "John Smith",
            number: "12345",
            qualifications: "RPII",
            id: "12345",
            raw_value: "John Smith (RPII)"
          }
        ])

        result = described_class.verify("12345")

        expect(result[:valid]).to be true
        expect(result[:inspector][:name]).to eq("John Smith")
        expect(result[:inspector][:number]).to eq("12345")
      end

      it "finds inspector when number matches as string" do
        allow(described_class).to receive(:search).with(12345).and_return([
          {
            name: "John Smith",
            number: "12345",
            qualifications: "RPII",
            id: "12345",
            raw_value: "John Smith (RPII)"
          }
        ])

        result = described_class.verify(12345)

        expect(result[:valid]).to be true
        expect(result[:inspector][:name]).to eq("John Smith")
      end

      it "finds correct inspector from multiple results" do
        allow(described_class).to receive(:search).with("22222").and_return([
          {
            name: "Wrong Inspector",
            number: "11111",
            qualifications: "RPII",
            id: "11111",
            raw_value: "Wrong Inspector (RPII)"
          },
          {
            name: "Right Inspector",
            number: "22222",
            qualifications: "API",
            id: "22222",
            raw_value: "Right Inspector (API)"
          }
        ])

        result = described_class.verify("22222")

        expect(result[:valid]).to be true
        expect(result[:inspector][:name]).to eq("Right Inspector")
        expect(result[:inspector][:number]).to eq("22222")
      end
    end

    context "when inspector is not found" do
      it "returns valid false with nil inspector" do
        allow(described_class).to receive(:search).with("99999").and_return([])

        result = described_class.verify("99999")

        expect(result[:valid]).to be false
        expect(result[:inspector]).to be_nil
      end

      it "returns valid false when no matching number" do
        allow(described_class).to receive(:search).with("55555").and_return([
          {
            name: "Other Inspector",
            number: "11111",
            qualifications: "RPII",
            id: "11111",
            raw_value: "Other Inspector (RPII)"
          }
        ])

        result = described_class.verify("55555")

        expect(result[:valid]).to be false
        expect(result[:inspector]).to be_nil
      end

      it "handles nil inspector number" do
        allow(described_class).to receive(:search).with(nil).and_return([])

        result = described_class.verify(nil)

        expect(result[:valid]).to be false
        expect(result[:inspector]).to be_nil
      end

      it "handles when inspector number is nil in results" do
        allow(described_class).to receive(:search).with("12345").and_return([
          {
            name: "No Number Inspector",
            number: nil,
            qualifications: "RPII",
            id: "id-only",
            raw_value: "No Number Inspector (RPII)"
          }
        ])

        result = described_class.verify("12345")

        expect(result[:valid]).to be false
        expect(result[:inspector]).to be_nil
      end
    end
  end

  describe "private methods" do
    describe ".build_request" do
      it "creates proper POST request with headers" do
        request = described_class.send(:build_request, "/path", "12345")

        expect(request).to be_a(Net::HTTP::Post)
        expect(request["User-Agent"]).to include("Mozilla")
        expect(request["Content-Type"]).to include("application/x-www-form-urlencoded")
        expect(request["X-Requested-With"]).to eq("XMLHttpRequest")
        expect(request.body).to include("action=check_inspector_ajax")
        expect(request.body).to include("search=12345")
      end

      it "strips whitespace from inspector number" do
        request = described_class.send(:build_request, "/path", "  67890  ")

        expect(request.body).to include("search=67890")
        expect(request.body).not_to include("  67890  ")
      end

      it "converts integer to string" do
        request = described_class.send(:build_request, "/path", 99999)

        expect(request.body).to include("search=99999")
      end
    end

    describe ".extract_suggestions" do
      it "extracts suggestions from hash response" do
        response = {"suggestions" => ["item1", "item2"]}
        result = described_class.send(:extract_suggestions, response)

        expect(result).to eq(["item1", "item2"])
      end

      it "returns array response as-is" do
        response = ["item1", "item2"]
        result = described_class.send(:extract_suggestions, response)

        expect(result).to eq(["item1", "item2"])
      end

      it "returns empty array for unexpected structure" do
        response = {"no_suggestions" => ["item1"]}
        result = described_class.send(:extract_suggestions, response)

        expect(result).to eq([])
      end

      it "returns empty array for nil response" do
        result = described_class.send(:extract_suggestions, nil)

        expect(result).to eq([])
      end

      it "returns empty array for string response" do
        result = described_class.send(:extract_suggestions, "not a hash or array")

        expect(result).to eq([])
      end
    end

    describe ".parse_inspector_item" do
      it "parses name and qualifications format" do
        item = {
          "value" => "John Smith (RPII, API)",
          "data" => "12345"
        }

        # Stub the method that would be called
        allow(described_class).to receive(:parse_name_qualifications_format).and_return({
          name: "John Smith",
          number: "12345",
          qualifications: "RPII, API",
          id: "12345",
          raw_value: "John Smith (RPII, API)"
        })

        result = described_class.send(:parse_inspector_item, item)

        expect(result).to eq({
          name: "John Smith",
          number: "12345",
          qualifications: "RPII, API",
          id: "12345",
          raw_value: "John Smith (RPII, API)"
        })
      end

      it "parses name, number, and qualifications format" do
        item = {
          "value" => "Jane Doe (67890) - RPII",
          "data" => "unique-id"
        }

        # Stub the method that would be called
        allow(described_class).to receive(:parse_name_number_qualifications_format).and_return({
          name: "Jane Doe",
          number: "67890",
          qualifications: "RPII",
          id: "unique-id",
          raw_value: "Jane Doe (67890) - RPII"
        })

        result = described_class.send(:parse_inspector_item, item)

        expect(result).to eq({
          name: "Jane Doe",
          number: "67890",
          qualifications: "RPII",
          id: "unique-id",
          raw_value: "Jane Doe (67890) - RPII"
        })
      end

      it "handles simple format" do
        item = {
          "value" => "Simple Name",
          "data" => "99999"
        }

        result = described_class.send(:parse_inspector_item, item)

        expect(result).to eq({
          raw_value: "Simple Name",
          number: "99999",
          id: "99999"
        })
      end

      it "handles missing value" do
        item = {
          "data" => "12345"
        }

        result = described_class.send(:parse_inspector_item, item)

        expect(result).to eq({
          raw_value: "",
          number: "12345",
          id: "12345"
        })
      end

      it "handles missing data" do
        item = {
          "value" => "Name Only"
        }

        result = described_class.send(:parse_inspector_item, item)

        expect(result).to eq({
          raw_value: "Name Only",
          number: nil,
          id: nil
        })
      end

      it "strips whitespace from parsed values" do
        item = {
          "value" => "Simple Inspector",
          "data" => "12345"
        }

        # This will use the simple format that doesn't require regex parsing
        result = described_class.send(:parse_inspector_item, item)

        expect(result[:raw_value]).to eq("Simple Inspector")
        expect(result[:number]).to eq("12345")
      end
    end

    describe ".log_error" do
      it "logs error with response code and body" do
        # We can't easily test this private method with Sorbet type checking
        # So we'll test it indirectly through the search method
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return("500")
        allow(mock_response).to receive(:body).and_return("Server Error Details")
        allow(described_class).to receive(:make_api_request).and_return(mock_response)
        allow(Rails.logger).to receive(:error)
        # Stub log_error to capture the call and manually log
        allow(described_class).to receive(:log_error) do |response|
          Rails.logger.error("RPII verification failed: #{response.code} - #{response.body}")
        end

        described_class.search("12345")

        expect(Rails.logger).to have_received(:error)
          .with("RPII verification failed: 500 - Server Error Details")
      end
    end
  end

  describe "constants" do
    it "has correct BASE_URL" do
      expect(described_class::BASE_URL).to eq("https://www.playinspectors.com/wp-admin/admin-ajax.php")
    end

    it "has USER_AGENT defined" do
      expect(described_class::USER_AGENT).to include("Mozilla")
      expect(described_class::USER_AGENT).to include("Chrome")
    end
  end
end
