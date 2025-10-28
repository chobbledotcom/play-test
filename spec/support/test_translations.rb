# typed: false

# Test-specific translations that are only used in specs
# These are not part of the production application

I18n.backend.store_translations(:en, {
  test: {
    password: "password123",
    access_denied: "Access denied",
    invalid_password: "wrongpassword",
    admin_emails_pattern: "^admin\\d*@example\\.com$"
  }
})
