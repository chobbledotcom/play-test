FactoryBot.define do
  factory :page do
    slug { "page-#{SecureRandom.hex(6)}" }
    meta_title { "Test Page" }
    meta_description { "Test page description" }
    link_title { "Test Link" }
    content { "<h1>Test Content</h1><p>This is test content.</p>" }
  end
end
