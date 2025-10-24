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
require "rails_helper"

RSpec.describe TextReplacement, type: :model do
  describe "validations" do
    it "requires i18n_key to be present" do
      replacement = TextReplacement.new(value: "Test value")
      expect(replacement).not_to be_valid
      expect(replacement.errors[:i18n_key]).to include("can't be blank")
    end

    it "requires i18n_key to be unique" do
      create(:text_replacement, i18n_key: "en.forms.test.field")
      duplicate = build(:text_replacement, i18n_key: "en.forms.test.field")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:i18n_key]).to include("has already been taken")
    end

    it "requires value to be present" do
      replacement = TextReplacement.new(i18n_key: "en.forms.test.field")
      expect(replacement).not_to be_valid
      expect(replacement.errors[:value]).to include("can't be blank")
    end
  end

  describe ".available_i18n_keys" do
    it "returns all i18n keys in the application" do
      I18n.backend.load_translations
      keys = TextReplacement.available_i18n_keys
      expect(keys).to be_an(Array)
      expect(keys).to include("en.admin_text_replacements.title")
      expect(keys).to eq(keys.sort)
    end
  end

  describe ".tree_structure" do
    it "returns empty hash when no replacements exist" do
      tree = TextReplacement.tree_structure
      expect(tree).to eq({})
    end

    it "builds a nested hash structure from flat keys" do
      replacement = create(:text_replacement,
        i18n_key: "en.forms.test.fields.name",
        value: "Custom Name")

      tree = TextReplacement.tree_structure
      expect(tree["en"]["forms"]["test"]["fields"]["name"][:_value]).to eq("Custom Name")
      expect(tree["en"]["forms"]["test"]["fields"]["name"][:_id]).to eq(replacement.id)
    end

    it "handles multiple replacements in the same namespace" do
      create(:text_replacement,
        i18n_key: "en.forms.test.fields.name",
        value: "Name")
      create(:text_replacement,
        i18n_key: "en.forms.test.fields.email",
        value: "Email")

      tree = TextReplacement.tree_structure
      fields = tree["en"]["forms"]["test"]["fields"]
      expect(fields["name"][:_value]).to eq("Name")
      expect(fields["email"][:_value]).to eq("Email")
    end
  end

  describe "creation" do
    it "creates a valid replacement with all attributes" do
      replacement = create(:text_replacement,
        i18n_key: "en.forms.test.submit",
        value: "Submit Form")
      expect(replacement).to be_persisted
      expect(replacement.i18n_key).to eq("en.forms.test.submit")
      expect(replacement.value).to eq("Submit Form")
    end
  end

  describe "i18n integration" do
    before do
      DatabaseI18nBackend.reload_cache
      I18n.backend.reload!
    end

    after do
      DatabaseI18nBackend.reload_cache
      I18n.backend.reload!
    end

    it "overrides i18n translations after creation" do
      original_value = I18n.t("admin_text_replacements.title")
      expect(original_value).to eq("Text Replacements")

      create(:text_replacement,
        i18n_key: "en.admin_text_replacements.title",
        value: "Custom Replacements")

      expect(I18n.t("admin_text_replacements.title")).to eq("Custom Replacements")
    end

    it "removes override when replacement is destroyed" do
      replacement = create(:text_replacement,
        i18n_key: "en.admin_text_replacements.title",
        value: "Custom Replacements")

      expect(I18n.t("admin_text_replacements.title")).to eq("Custom Replacements")

      replacement.destroy

      expect(I18n.t("admin_text_replacements.title")).to eq("Text Replacements")
    end

    it "updates i18n when replacement value changes" do
      replacement = create(:text_replacement,
        i18n_key: "en.admin_text_replacements.title",
        value: "Custom Replacements")

      expect(I18n.t("admin_text_replacements.title")).to eq("Custom Replacements")

      replacement.update(value: "Updated Replacements")

      expect(I18n.t("admin_text_replacements.title")).to eq("Updated Replacements")
    end
  end
end
