# typed: false

# == Schema Information
#
# Table name: inspector_companies
#
#  id          :string(12)       not null, primary key
#  active      :boolean          default(TRUE)
#  address     :text             not null
#  city        :string
#  country     :string           default("UK")
#  email       :string
#  name        :string           not null
#  notes       :text
#  phone       :string           not null
#  postal_code :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_inspector_companies_on_active  (active)
#
require "rails_helper"

RSpec.describe InspectorCompany, type: :model do
  describe "associations" do
    let(:company) { create(:inspector_company) }

    it "has many inspections" do
      expect(company).to respond_to(:inspections)
    end
  end

  describe "validations" do
    it "validates presence of name" do
      company = build(:inspector_company, name: nil)
      expect(company).not_to be_valid
      expect(company.errors[:name]).to be_present
    end

    it "validates presence of phone" do
      company = build(:inspector_company, phone: nil)
      expect(company).not_to be_valid
      expect(company.errors[:phone]).to be_present
    end

    it "validates presence of address" do
      company = build(:inspector_company, address: nil)
      expect(company).not_to be_valid
      expect(company.errors[:address]).to be_present
    end

    it "validates email format when present" do
      company = build(:inspector_company, email: "invalid-email")
      expect(company).not_to be_valid
      expect(company.errors[:email]).to be_present
    end

    it "allows blank email" do
      company = build(:inspector_company, email: "")
      expect(company).to be_valid
    end

    it "allows valid email" do
      company = build(:inspector_company)
      expect(company).to be_valid
    end
  end

  describe "scopes" do
    let!(:active_company) { create(:inspector_company) }
    let!(:inactive_company) { create(:inspector_company, :inactive) }

    describe ".active" do
      it "returns only active companies" do
        expect(InspectorCompany.active).to include(active_company)
        expect(InspectorCompany.active).not_to include(inactive_company)
      end
    end
  end

  describe "phone formatting" do
    it "normalizes phone numbers by removing non-digits" do
      company = create(:inspector_company, phone: "(123) 456-7890")
      expect(company.phone).to eq("1234567890")
    end

    it "handles international phone numbers" do
      company = create(:inspector_company, phone: "+44 20 1234 5678")
      expect(company.phone).to eq("442012345678")
    end
  end

  describe "methods" do
    let(:company) { create(:inspector_company) }

    # Credentials validation moved to user level - no longer relevant for companies

    describe "#full_address" do
      it "combines address components" do
        company.address = "123 Test St"
        company.city = "Test City"
        company.postal_code = "12345"

        expect(company.full_address).to eq("123 Test St, Test City, 12345")
      end

      it "handles missing components" do
        company.address = "123 Test St"
        company.city = "Test City"
        company.postal_code = nil

        expect(company.full_address).to eq("123 Test St, Test City")
      end
    end

    describe "#inspection_count" do
      it "returns the number of inspections" do
        expect(company.inspection_count).to eq(0)
      end
    end

    describe "#pass_rate" do
      it "returns 0 when no inspections" do
        expect(company.pass_rate).to eq(0)
      end

      it "rounds the percentage to two decimal places" do
        expect(company.pass_rate(3, 1)).to eq(33.33)
      end

      it "computes the rate from the company inspections" do
        user = create(:user, inspection_company: company)
        create(:inspection, :passed, user: user)
        create_list(:inspection, 3, :failed, user: user)

        expect(company.pass_rate).to eq(25.0)
      end
    end

    describe "#company_statistics" do
      it "returns comprehensive statistics" do
        stats = company.company_statistics
        expect(stats).to include(
          :total_inspections,
          :passed_inspections,
          :failed_inspections,
          :pass_rate,
          :active_since
        )
      end

      it "counts passed and failed inspections" do
        user = create(:user, inspection_company: company)
        create_list(:inspection, 2, :passed, user: user)
        create(:inspection, :failed, user: user)

        stats = company.company_statistics

        expect(stats[:total_inspections]).to eq(3)
        expect(stats[:passed_inspections]).to eq(2)
        expect(stats[:failed_inspections]).to eq(1)
        expect(stats[:pass_rate]).to eq(66.67)
        expect(stats[:active_since]).to eq(company.created_at.year)
      end

      it "reports zero failed when every inspection passed" do
        user = create(:user, inspection_company: company)
        create(:inspection, :passed, user: user)

        stats = company.company_statistics

        expect(stats[:passed_inspections]).to eq(1)
        expect(stats[:failed_inspections]).to eq(0)
      end

      it "reports zero passed when every inspection failed" do
        user = create(:user, inspection_company: company)
        create(:inspection, :failed, user: user)

        stats = company.company_statistics

        expect(stats[:passed_inspections]).to eq(0)
        expect(stats[:failed_inspections]).to eq(1)
      end
    end

    describe "#recent_inspections" do
      it "returns inspections most recent first, limited" do
        user = create(:user, inspection_company: company)
        old = create(:inspection, user: user, inspection_date: 3.days.ago)
        mid = create(:inspection, user: user, inspection_date: 2.days.ago)
        recent = create(:inspection, user: user, inspection_date: 1.day.ago)

        expect(company.recent_inspections(2)).to eq([recent, mid])
        expect(company.recent_inspections(2)).not_to include(old)
      end

      it "defaults to returning at most ten inspections" do
        user = create(:user, inspection_company: company)
        create_list(:inspection, 11, user: user)

        expect(company.recent_inspections.length).to eq(10)
      end
    end

    describe ".form_schema" do
      it "includes the notes field for admins" do
        admin = create(:user, :admin)
        schema = InspectorCompany.form_schema(user: admin)

        expect(schema.find_field(:notes)).to be_present
      end

      it "excludes the notes field for non-admins" do
        schema = InspectorCompany.form_schema(user: create(:user))

        expect(schema.find_field(:notes)).to be_nil
      end

      it "excludes the notes field when no user is given" do
        expect(InspectorCompany.form_schema.find_field(:notes)).to be_nil
      end
    end

    describe "#logo_url" do
      it "returns nil when no logo attached" do
        expect(company.logo_url).to be_nil
      end

      it "returns the logo when one is attached" do
        company.logo.attach(fixture_file_upload("test_image.jpg", "image/jpeg"))

        expect(company.logo_url).to eq(company.logo)
      end
    end
  end

  describe "file attachments" do
    let(:company) { create(:inspector_company) }

    it "can attach a logo" do
      expect(company).to respond_to(:logo)
    end
  end
end
