# typed: true
# frozen_string_literal: true

module CustomIdGenerator
  extend ActiveSupport::Concern
  extend T::Sig

  # Standard ID length for all models using CustomIdGenerator
  ID_LENGTH = 8

  included do
    self.primary_key = "id"
    before_create :generate_custom_id, if: -> { id.blank? }
  end

  class_methods do
    extend T::Sig

    sig { params(scope_conditions: T::Hash[T.untyped, T.untyped]).returns(String) }
    def generate_random_id(scope_conditions = {})
      loop do
        id = SecureRandom.alphanumeric(CustomIdGenerator::ID_LENGTH).upcase
        break id unless exists?({id: id}.merge(scope_conditions))
      end
    end
  end

  private

  sig { void }
  def generate_custom_id
    scope_conditions = respond_to?(:uniqueness_scope) ? uniqueness_scope : {}
    self.id = self.class.generate_random_id(scope_conditions)
  end
end
