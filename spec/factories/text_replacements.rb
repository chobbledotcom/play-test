# typed: false

# == Schema Information
#
# Table name: text_replacements
#
#  id         :integer          not null, primary key
#  i18n_key   :string           not null
#  value      :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :text_replacement do
    sequence(:i18n_key) { |n| "en.test.key_#{n}" }
    value { "Test replacement value" }
  end
end
