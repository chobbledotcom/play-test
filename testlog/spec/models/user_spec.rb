require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "requires an email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires a valid email format" do
      user = build(:user, email: "invalid-email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "requires a password" do
      user = build(:user, password: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "requires a password of at least 6 characters" do
      user = build(:user, password: "short", password_confirmation: "short")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)")
    end

    it "requires a unique email" do
      create(:user, email: "duplicate@example.com")
      duplicate_user = build(:user, email: "duplicate@example.com")

      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "has many inspections" do
      user = User.reflect_on_association(:inspections)
      expect(user.macro).to eq(:has_many)
    end

    it "has dependent destroy on inspections" do
      user = User.reflect_on_association(:inspections)
      expect(user.options[:dependent]).to eq(:destroy)
    end
  end

  describe "custom ID generation" do
    it "generates string IDs using CustomIdGenerator" do
      user = create(:user)

      # Verify ID is a string
      expect(user.id).to be_a(String)

      # Verify ID follows the expected format (12 uppercase alphanumeric characters)
      expect(user.id).to match(/\A[A-Z0-9]{12}\z/)

      # Verify ID is unique for multiple users
      second_user = create(:user)

      expect(second_user.id).to be_a(String)
      expect(second_user.id).to match(/\A[A-Z0-9]{12}\z/)
      expect(second_user.id).not_to eq(user.id)
    end
  end

  describe "admin functionality" do
    it "determines admin status based on ENV configuration" do
      # Create a user with admin email pattern
      admin_user = create(:user, :admin)

      # Create a regular user
      regular_user = create(:user)

      # Verify admin user is detected as admin
      expect(admin_user.admin?).to be true

      # Verify regular user is not admin
      expect(regular_user.admin?).to be false
    end
  end

  describe "inspection_limit" do
    it "defaults to 10 when LIMIT_INSPECTIONS is not set" do
      # Ensure environment variable is not set
      allow(ENV).to receive(:[]).with("LIMIT_INSPECTIONS").and_return(nil)

      user = create(:user)
      expect(user.inspection_limit).to eq(10)
    end

    it "uses LIMIT_INSPECTIONS environment variable when set" do
      # Mock the environment variable
      allow(ENV).to receive(:[]).with("LIMIT_INSPECTIONS").and_return("20")

      user = create(:user)
      expect(user.inspection_limit).to eq(20)
    end

    it "allows unlimited inspections when LIMIT_INSPECTIONS is -1" do
      # Mock the environment variable
      allow(ENV).to receive(:[]).with("LIMIT_INSPECTIONS").and_return("-1")

      user = create(:user)
      expect(user.inspection_limit).to eq(-1)
      expect(user.can_create_inspection?).to be true
    end

    it "validates that inspection_limit is -1 or a non-negative integer" do
      user = build(:user, inspection_limit: -2)
      expect(user).not_to be_valid
      expect(user.errors[:inspection_limit]).to include("must be greater than or equal to -1")
    end

    describe "#can_create_inspection?" do
      it "returns true when user has fewer inspections than their limit" do
        user = create(:user, :limited_inspections)
        create(:inspection, user: user)
        expect(user.can_create_inspection?).to be true
      end

      it "returns false when user has reached their inspection limit (for non-unlimited users)" do
        allow_any_instance_of(User).to receive(:set_default_inspection_limit)

        # Create a user with a specific limit
        user = build(:user, inspection_limit: 1)
        user.save!

        # Create an inspection to reach the limit
        create(:inspection, user: user)

        # Force reload the user to ensure counts are updated
        user.reload

        # Check the state before testing can_create_inspection?
        expect(user.inspection_limit).to eq(1)
        expect(user.inspections.count).to eq(1)

        # Now test the method
        expect(user.can_create_inspection?).to be false
      end

      it "returns true when user has unlimited inspections (-1)" do
        user = create(:user, :unlimited_inspections)

        # Create more than a typical limit to verify unlimited works
        create_list(:inspection, 5, user: user)

        expect(user.can_create_inspection?).to be true
      end
    end
  end
end
