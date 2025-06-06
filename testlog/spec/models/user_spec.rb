require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      user = User.new(
        email: "test@example.com",
        password: "password",
        password_confirmation: "password"
      )
      expect(user).to be_valid
    end

    it "requires an email" do
      user = User.new(password: "password", password_confirmation: "password")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires a valid email format" do
      user = User.new(
        email: "invalid-email",
        password: "password",
        password_confirmation: "password"
      )
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "requires a password" do
      user = User.new(email: "test@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "requires a password of at least 6 characters" do
      user = User.new(
        email: "test@example.com",
        password: "short",
        password_confirmation: "short"
      )
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)")
    end

    it "requires a unique email" do
      # Create a user with a specific email
      User.create!(
        email: "duplicate@example.com",
        password: "password",
        password_confirmation: "password"
      )

      # Try to create another user with the same email
      duplicate_user = User.new(
        email: "duplicate@example.com",
        password: "password",
        password_confirmation: "password"
      )

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

  describe "admin functionality" do
    it "sets the first user as admin" do
      # Make sure there are no users
      User.destroy_all

      # Create the first user
      first_user = User.create!(
        email: "admin@example.com",
        password: "password",
        password_confirmation: "password"
      )

      # Create a second user
      second_user = User.create!(
        email: "regular@example.com",
        password: "password",
        password_confirmation: "password"
      )

      # Verify the first user is an admin
      expect(first_user.admin?).to be true

      # Verify the second user is not an admin
      expect(second_user.admin?).to be false
    end
  end

  describe "inspection_limit" do
    it "defaults to 10 when LIMIT_INSPECTIONS is not set" do
      # Ensure environment variable is not set
      allow(ENV).to receive(:[]).with("LIMIT_INSPECTIONS").and_return(nil)

      user = User.create!(
        email: "test@example.com",
        password: "password",
        password_confirmation: "password"
      )
      expect(user.inspection_limit).to eq(10)
    end

    it "uses LIMIT_INSPECTIONS environment variable when set" do
      # Mock the environment variable
      allow(ENV).to receive(:[]).with("LIMIT_INSPECTIONS").and_return("20")

      user = User.create!(
        email: "test@example.com",
        password: "password",
        password_confirmation: "password"
      )
      expect(user.inspection_limit).to eq(20)
    end

    it "allows unlimited inspections when LIMIT_INSPECTIONS is -1" do
      # Mock the environment variable
      allow(ENV).to receive(:[]).with("LIMIT_INSPECTIONS").and_return("-1")

      user = User.create!(
        email: "test@example.com",
        password: "password",
        password_confirmation: "password"
      )
      expect(user.inspection_limit).to eq(-1)
      expect(user.can_create_inspection?).to be true
    end

    it "validates that inspection_limit is -1 or a non-negative integer" do
      user = User.new(
        email: "test@example.com",
        password: "password",
        password_confirmation: "password",
        inspection_limit: -2
      )
      expect(user).not_to be_valid
      expect(user.errors[:inspection_limit]).to include("must be greater than or equal to -1")
    end

    describe "#can_create_inspection?" do
      it "returns true when user has fewer inspections than their limit" do
        user = User.create!(
          email: "test@example.com",
          password: "password",
          password_confirmation: "password",
          inspection_limit: 2
        )
        user.inspections.create!(
          inspector: "John Doe",
          serial: "PAT-123",
          location: "Test Location",
          manufacturer: "Test Manufacturer",
          passed: true
        )
        expect(user.can_create_inspection?).to be true
      end

      it "returns false when user has reached their inspection limit (for non-unlimited users)" do
        allow_any_instance_of(User).to receive(:set_default_inspection_limit)

        # Create a user with a specific limit
        user = User.new(
          email: "test@example.com",
          password: "password",
          password_confirmation: "password"
        )
        # Manually set inspection limit to avoid callbacks
        user.inspection_limit = 1
        user.save!

        # Create an inspection to reach the limit
        user.inspections.create!(
          inspector: "John Doe",
          serial: "PAT-123",
          location: "Test Location",
          manufacturer: "Test Manufacturer",
          passed: true
        )

        # Force reload the user to ensure counts are updated
        user.reload

        # Check the state before testing can_create_inspection?
        expect(user.inspection_limit).to eq(1)
        expect(user.inspections.count).to eq(1)

        # Now test the method
        expect(user.can_create_inspection?).to be false
      end

      it "returns true when user has unlimited inspections (-1)" do
        user = User.create!(
          email: "test@example.com",
          password: "password",
          password_confirmation: "password",
          inspection_limit: -1
        )

        # Create more than a typical limit to verify unlimited works
        5.times do |i|
          user.inspections.create!(
            inspector: "John Doe",
            serial: "PAT-#{i}",
            location: "Test Location",
            manufacturer: "Test Manufacturer",
            passed: true
          )
        end

        expect(user.can_create_inspection?).to be true
      end
    end
  end
end
