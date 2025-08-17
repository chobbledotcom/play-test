# == Schema Information
#
# Table name: credentials
#
#  id          :integer          not null, primary key
#  nickname    :string           not null
#  public_key  :string           not null
#  sign_count  :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  external_id :string           not null
#  user_id     :string(12)       not null
#
# Indexes
#
#  index_credentials_on_external_id  (external_id) UNIQUE
#  index_credentials_on_user_id      (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
require "rails_helper"

RSpec.describe Credential, type: :model do
  describe "associations" do
    it "belongs to a user" do
      association = Credential.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      credential = build(:credential)
      expect(credential).to be_valid
    end

    it "requires an external_id" do
      credential = build(:credential, external_id: nil)
      expect(credential).not_to be_valid
      expect(credential.errors[:external_id]).to include("can't be blank")
    end

    it "requires a public_key" do
      credential = build(:credential, public_key: nil)
      expect(credential).not_to be_valid
      expect(credential.errors[:public_key]).to include("can't be blank")
    end

    it "requires a nickname" do
      credential = build(:credential, nickname: nil)
      expect(credential).not_to be_valid
      expect(credential.errors[:nickname]).to include("can't be blank")
    end

    it "requires a sign_count" do
      credential = build(:credential, sign_count: nil)
      expect(credential).not_to be_valid
      expect(credential.errors[:sign_count]).to include("can't be blank")
    end

    it "requires a unique external_id" do
      existing_credential = create(:credential)
      new_credential = build(:credential, external_id: existing_credential.external_id)
      expect(new_credential).not_to be_valid
      expect(new_credential.errors[:external_id]).to include("has already been taken")
    end

    it "requires sign_count to be an integer" do
      credential = build(:credential, sign_count: 1.5)
      expect(credential).not_to be_valid
      expect(credential.errors[:sign_count]).to include("must be an integer")
    end

    it "requires sign_count to be non-negative" do
      credential = build(:credential, sign_count: -1)
      expect(credential).not_to be_valid
      expect(credential.errors[:sign_count]).to include("must be greater than or equal to 0")
    end

    it "requires sign_count to be within 32-bit unsigned integer range" do
      credential = build(:credential, sign_count: 2**32)
      expect(credential).not_to be_valid
      expect(credential.errors[:sign_count]).to include("must be less than or equal to #{(2**32) - 1}")
    end
  end

  describe "factory" do
    it "creates a valid credential" do
      credential = build(:credential)
      expect(credential).to be_valid
    end

    it "creates a credential associated with a user" do
      credential = create(:credential)
      expect(credential.user).to be_present
      expect(credential.user).to be_a(User)
    end
  end

  describe "sign_count boundary values" do
    it "accepts zero as sign_count" do
      credential = build(:credential, sign_count: 0)
      expect(credential).to be_valid
    end

    it "accepts maximum 32-bit unsigned integer value" do
      max_value = (2**32) - 1
      credential = build(:credential, sign_count: max_value)
      expect(credential).to be_valid
    end
  end
end
