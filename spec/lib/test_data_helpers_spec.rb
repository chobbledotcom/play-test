require "rails_helper"

RSpec.describe TestDataHelpers do
  describe ".british_phone_number" do
    it "generates valid UK mobile number format" do
      phone = described_class.british_phone_number

      expect(phone).to match(/\A07\d{3} \d{3} \d{4}\z/)
      expect(phone.length).to eq(14) # "07xxx xxx xxxx"
    end

    it "always starts with 07" do
      phone = described_class.british_phone_number

      expect(phone).to start_with("07")
    end

    it "has correct spacing" do
      phone = described_class.british_phone_number

      expect(phone[5]).to eq(" ")
      expect(phone[9]).to eq(" ")
    end

    it "generates different numbers on multiple calls" do
      numbers = 10.times.map { described_class.british_phone_number }

      expect(numbers.uniq.size).to be > 1
    end
  end

  describe ".british_postcode" do
    it "generates valid UK postcode format" do
      postcode = described_class.british_postcode

      # UK postcode format: letters + numbers + space + number + two letters
      expect(postcode).to match(/\A[A-Z]{1,2}\d{1,2} \d[A-Z]{2}\z/)
    end

    it "uses valid postcode prefixes" do
      prefixes = ["SW", "SE", "NW", "N", "E", "W", "EC", "WC", "B", "M", "L", "G", "EH", "CF", "BS", "OX", "CB"]
      postcode = described_class.british_postcode
      prefix = postcode.split(/\d/).first

      expect(prefixes).to include(prefix)
    end

    it "has a space separating inward and outward codes" do
      postcode = described_class.british_postcode

      expect(postcode).to include(" ")
    end

    it "generates different postcodes on multiple calls" do
      postcodes = 10.times.map { described_class.british_postcode }

      expect(postcodes.uniq.size).to be > 1
    end
  end

  describe ".british_address" do
    it "generates address with number and street name" do
      address = described_class.british_address

      expect(address).to match(/\A\d+ .+\z/)
    end

    it "uses valid British street names" do
      expected_streets = ["High Street", "Church Lane", "Victoria Road", "King's Road", "Queen Street",
        "Park Avenue", "Station Road", "London Road", "Market Square", "The Green"]
      address = described_class.british_address
      street_name = address.split(" ", 2).last

      expect(expected_streets).to include(street_name)
    end

    it "uses house numbers between 1 and 200" do
      address = described_class.british_address
      house_number = address.split(" ").first.to_i

      expect(house_number).to be_between(1, 200)
    end

    it "generates different addresses on multiple calls" do
      addresses = 10.times.map { described_class.british_address }

      expect(addresses.uniq.size).to be > 1
    end
  end

  describe ".british_city" do
    it "returns a valid British city" do
      expected_cities = ["London", "Birmingham", "Manchester", "Leeds", "Liverpool", "Newcastle", "Bristol",
        "Sheffield", "Nottingham", "Leicester", "Oxford", "Cambridge", "Brighton", "Southampton",
        "Edinburgh", "Glasgow", "Cardiff", "Belfast"]
      city = described_class.british_city

      expect(expected_cities).to include(city)
    end

    it "returns a string" do
      city = described_class.british_city

      expect(city).to be_a(String)
      expect(city).not_to be_empty
    end

    it "can return different cities on multiple calls" do
      cities = 20.times.map { described_class.british_city }

      expect(cities.uniq.size).to be > 1
    end
  end

  describe ".british_company_name" do
    context "with base name provided" do
      it "appends valid British company suffix" do
        base_name = "TestCorp"
        company_name = described_class.british_company_name(base_name)

        expect(company_name).to start_with("TestCorp ")
      end

      it "uses valid company suffixes" do
        expected_suffixes = ["Ltd", "UK", "Services", "Solutions", "Group", "& Co", "International"]
        base_name = "ABC"
        company_name = described_class.british_company_name(base_name)
        suffix = company_name.split(" ", 2).last

        expect(expected_suffixes).to include(suffix)
      end
    end

    context "with empty base name" do
      it "handles empty string gracefully" do
        company_name = described_class.british_company_name("")

        expect(company_name).to start_with(" ")
        expect(company_name.strip).not_to be_empty
      end
    end

    context "with nil base name" do
      it "handles nil gracefully" do
        expect { described_class.british_company_name(nil) }.not_to raise_error
      end
    end

    it "generates different company names for same base" do
      base_name = "TestCorp"
      names = 10.times.map { described_class.british_company_name(base_name) }

      expect(names.uniq.size).to be > 1
    end
  end

  describe "data consistency" do
    it "all methods return non-empty strings" do
      expect(described_class.british_phone_number).not_to be_empty
      expect(described_class.british_postcode).not_to be_empty
      expect(described_class.british_address).not_to be_empty
      expect(described_class.british_city).not_to be_empty
      expect(described_class.british_company_name("Test")).not_to be_empty
    end

    it "all methods are deterministically random" do
      # Each method should potentially return different values
      methods_to_test = [
        :british_phone_number,
        :british_postcode,
        :british_address,
        :british_city
      ]

      methods_to_test.each do |method|
        results = 5.times.map { described_class.send(method) }
        expect(results).to all(be_a(String))
        expect(results).to all(be_present)
      end
    end
  end
end
