# typed: false
# frozen_string_literal: true

require_relative "../../lib/database_i18n_backend"

Rails.application.config.after_initialize do
  I18n.backend = DatabaseI18nBackend.new
  Rails.logger.info "Initialized DatabaseI18nBackend for I18n"
end
