require "rails_helper"

RSpec.describe InspectorCompany, type: :model do
  let(:user) { create(:user) }

  describe "associations" do
    let(:company) { create(:inspector_company, user: user) }

    it "belongs to user" do
      expect(company.user).to eq(user)
    end

    it "has many inspections" do
      expect(company).to respond_to(:inspections)
    end
  end

  describe "validations" do
    it "validates presence of name" do
      company = build(:inspector_company, user: user, name: nil)
      expect(company).not_to be_valid
      expect(company.errors[:name]).to be_present
    end

    it "validates presence of rpii_registration_number" do
      company = build(:inspector_company, user: user, rpii_registration_number: nil)
      expect(company).not_to be_valid
      expect(company.errors[:rpii_registration_number]).to be_present
    end

    it "validates uniqueness of rpii_registration_number" do
      create(:inspector_company, user: user, rpii_registration_number: "RPII123")
      company = build(:inspector_company, user: user, rpii_registration_number: "RPII123")
      expect(company).not_to be_valid
      expect(company.errors[:rpii_registration_number]).to be_present
    end

    it "validates presence of phone" do
      company = build(:inspector_company, user: user, phone: nil)
      expect(company).not_to be_valid
      expect(company.errors[:phone]).to be_present
    end

    it "validates presence of address" do
      company = build(:inspector_company, user: user, address: nil)
      expect(company).not_to be_valid
      expect(company.errors[:address]).to be_present
    end

    it "validates email format when present" do
      company = build(:inspector_company, user: user, email: "invalid-email")
      expect(company).not_to be_valid
      expect(company.errors[:email]).to be_present

      company.email = "valid@example.com"
      expect(company).to be_valid
    end

    it "allows blank email" do
      company = build(:inspector_company, user: user, email: "")
      expect(company).to be_valid
    end
  end

  describe "custom ID generation" do
    it "generates a custom ID before creation" do
      company = build(:inspector_company, user: user)
      expect(company.id).to be_nil
      company.save!
      expect(company.id).to match(/\A[A-Z0-9]{12}\z/)
    end
  end

  describe "scopes" do
    let!(:verified_company) { create(:inspector_company, :verified, user: user) }
    let!(:unverified_company) { create(:inspector_company, user: user) }
    let!(:inactive_company) { create(:inspector_company, :inactive, user: user) }

    describe ".verified" do
      it "returns only verified companies" do
        expect(InspectorCompany.verified).to include(verified_company)
        expect(InspectorCompany.verified).not_to include(unverified_company)
      end
    end

    describe ".active" do
      it "returns only active companies" do
        expect(InspectorCompany.active).to include(verified_company)
        expect(InspectorCompany.active).to include(unverified_company)
        expect(InspectorCompany.active).not_to include(inactive_company)
      end
    end
  end

  describe "callbacks" do
    describe "#normalize_phone_number" do
      it "removes non-digit characters from phone" do
        company = create(:inspector_company, :formatted_phone, user: user)
        expect(company.phone).to eq("1234567890")
      end

      it "handles international format" do
        company = create(:inspector_company, :international_phone, user: user)
        expect(company.phone).to eq("442012345678")
      end
    end
  end

  describe "methods" do
    let(:company) { create(:inspector_company, user: user) }

    describe "#has_valid_credentials?" do
      it "returns true when RPII number is present and verified" do
        company.rpii_verified = true
        expect(company.has_valid_credentials?).to be_truthy
      end

      it "returns false when not verified" do
        company.rpii_verified = false
        expect(company.has_valid_credentials?).to be_falsy
      end

      it "returns false when RPII number is blank" do
        company.rpii_registration_number = ""
        company.rpii_verified = true
        expect(company.has_valid_credentials?).to be_falsy
      end
    end

    describe "#full_address" do
      it "combines address components" do
        company.address = "123 Test St"
        company.city = "Test City"
        company.state = "Test State"
        company.postal_code = "12345"

        expect(company.full_address).to eq("123 Test St, Test City, Test State, 12345")
      end

      it "handles missing components" do
        company.address = "123 Test St"
        company.city = "Test City"
        company.state = nil
        company.postal_code = "12345"

        expect(company.full_address).to eq("123 Test St, Test City, 12345")
      end
    end

    describe "#inspection_count" do
      it "responds to inspection_count method" do
        expect(company).to respond_to(:inspection_count)
        # Will test actual count when inspection relationship is established
      end
    end

    describe "#pass_rate" do
      it "responds to pass_rate method" do
        expect(company).to respond_to(:pass_rate)
        # Will test actual pass rate when inspection relationship is established
      end
    end

    describe "#company_statistics" do
      it "responds to company_statistics method" do
        expect(company).to respond_to(:company_statistics)
        # Will test actual statistics when inspection relationship is established
      end
    end
  end

  describe "file attachments" do
    let(:company) { create(:inspector_company, user: user) }

    it "has one attached logo" do
      expect(company).to respond_to(:logo)
      expect(company.logo).to be_an_instance_of(ActiveStorage::Attached::One)
    end

    describe "#logo_url" do
      it "returns logo when attached" do
        # Create a test file using built-in file
        file = fixture_file_upload("test_image.jpg", "image/jpeg")
        company.logo.attach(file)

        expect(company.logo_url).to eq(company.logo)
      end

      it "returns nil when no logo attached" do
        expect(company.logo_url).to be_nil
      end
    end
  end
end
