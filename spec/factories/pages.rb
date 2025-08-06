# == Schema Information
#
# Table name: pages
#
#  content          :text
#  is_snippet       :boolean          default(FALSE), not null
#  link_title       :string
#  meta_description :text
#  meta_title       :string
#  slug             :string           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
FactoryBot.define do
  factory :page do
    slug { "page-#{SecureRandom.hex(6)}" }
    meta_title { "Test Page" }
    meta_description { "Test page description" }
    link_title { "Test Link" }
    content { "<h1>Test Content</h1><p>This is test content.</p>" }
  end
end
