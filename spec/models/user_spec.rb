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

  describe "active_until" do
    it "defaults to yesterday (inactive on signup)" do
      user = create(:user, :newly_signed_up)
      expect(user.active_until).to eq(Date.current - 1.day)
      expect(user.is_active?).to be false # Yesterday means inactive
    end

    describe "#is_active?" do
      it "returns true when active_until is nil" do
        user = create(:user, active_until: nil)
        expect(user.is_active?).to be true
      end

      it "returns true when active_until is in the future" do
        user = create(:user, active_until: Date.current + 1.day)
        expect(user.is_active?).to be true
      end

      it "returns true when active_until is today" do
        user = create(:user, active_until: Date.current)
        expect(user.is_active?).to be true
      end

      it "returns false when active_until is in the past" do
        user = create(:user, active_until: Date.current - 1.day)
        expect(user.is_active?).to be false
      end
    end

    describe "#can_create_inspection?" do
      it "returns true when user is active" do
        user = create(:user, :active_user)
        expect(user.can_create_inspection?).to be true
      end

      it "returns false when user is inactive" do
        user = create(:user, :inactive_user)
        expect(user.can_create_inspection?).to be false
      end
    end

    describe "#inactive_user_message" do
      it "returns inactive user message" do
        user = create(:user)
        expect(user.inactive_user_message).to eq(
          I18n.t("users.messages.user_inactive")
        )
      end
    end
  end
end
