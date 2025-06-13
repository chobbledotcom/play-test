require "rails_helper"

ALLOWED_TOP_LEVEL_KEYS = %w[header sections fields placeholders hints status summary submit issues errors].freeze

RSpec.describe "Form I18n Structure" do
  def check_form_locale_file(file_path)
    locale_data = YAML.load_file(file_path)
    form_name = File.basename(file_path, ".en.yml")

    # Navigate to the form data
    form_data = locale_data.dig("en", "forms", form_name)
    return [] unless form_data

    # Get all top-level keys
    actual_keys = form_data.keys

    # Find any keys that aren't in the allowed list
    invalid_keys = actual_keys - ALLOWED_TOP_LEVEL_KEYS

    invalid_keys.map { |key| "#{form_name}: #{key}" }
  end

  it "only contains allowed top-level keys in form locale files" do
    form_locale_dir = Rails.root.join("config/locales/forms")
    form_files = Dir.glob(form_locale_dir.join("*.en.yml"))

    all_invalid_keys = []

    form_files.each do |file|
      invalid_keys = check_form_locale_file(file)
      all_invalid_keys.concat(invalid_keys)
    end

    if all_invalid_keys.any?
      fail_message = "Found invalid top-level keys in form locale files:\n"
      fail_message += all_invalid_keys.map { |key| "  - #{key}" }.join("\n")
      fail_message += "\n\nAllowed keys: #{ALLOWED_TOP_LEVEL_KEYS.join(", ")}"

      expect(all_invalid_keys).to be_empty, fail_message
    end
  end

  it "lists all top-level keys found in form locale files" do
    form_locale_dir = Rails.root.join("config/locales/forms")
    form_files = Dir.glob(form_locale_dir.join("*.en.yml"))

    all_keys = {}

    form_files.each do |file|
      locale_data = YAML.load_file(file)
      form_name = File.basename(file, ".en.yml")
      form_data = locale_data.dig("en", "forms", form_name)

      next unless form_data

      all_keys[form_name] = form_data.keys.sort
    end

    # This test doesn't fail, just prints information
    puts "\nTop-level keys by form:"
    all_keys.each do |form, keys|
      puts "  #{form}: #{keys.join(", ")}"
    end
  end
end
