# typed: false

# Test-specific translations must survive I18n.backend.reload! calls.
test_translations = Rails.root.join("spec/support/test_translations.en.yml")
I18n.load_path << test_translations.to_s
I18n.backend.load_translations(test_translations)
