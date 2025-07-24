require "rails_helper"

RSpec.describe Page, type: :model do
  describe "validations" do
    it "requires slug to be present" do
      page = Page.new(link_title: "Test", content: "Test content")
      expect(page).not_to be_valid
      expect(page.errors[:slug]).to include("can't be blank")
    end

    it "requires slug to be unique" do
      create(:page, slug: "test-page")
      duplicate = build(:page, slug: "test-page")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("has already been taken")
    end

    it "requires link_title to be present" do
      page = Page.new(slug: "test", content: "Test content")
      expect(page).not_to be_valid
      expect(page.errors[:link_title]).to include("can't be blank")
    end

    it "requires content to be present" do
      page = Page.new(slug: "test", link_title: "Test")
      expect(page).not_to be_valid
      expect(page.errors[:content]).to include("can't be blank")
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      page = Page.new(slug: "test-page")
      expect(page.to_param).to eq("test-page")
    end
  end

  describe "creation" do
    it "creates a valid page with all attributes" do
      page = create(:page,
        slug: "test",
        link_title: "Test Page",
        meta_title: "Test Meta Title",
        meta_description: "Test meta description",
        content: "<h1>Test</h1>")
      expect(page).to be_persisted
      expect(page.slug).to eq("test")
    end
  end
end
