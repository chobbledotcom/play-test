FactoryBot.define do
  factory :credential do
    user { nil }
    external_id { "MyString" }
    public_key { "MyString" }
    nickname { "MyString" }
    sign_count { 1 }
  end
end
