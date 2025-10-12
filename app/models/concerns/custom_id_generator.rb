# typed: true
# frozen_string_literal: true

module CustomIdGenerator
  extend ActiveSupport::Concern
  extend T::Sig

  # Standard ID length for all models using CustomIdGenerator
  ID_LENGTH = 8

  # Ambiguous characters to exclude from IDs
  AMBIGUOUS_CHARS = %w[0 O 1 I L].freeze

  included do
    self.primary_key = "id"
    before_create :generate_custom_id, if: -> { id.blank? }
  end

  class_methods do
    extend T::Sig

    sig do
      params(scope_conditions: T::Hash[T.untyped, T.untyped]).returns(String)
    end
    def generate_random_id(scope_conditions = {})
      loop do
        raw_id = SecureRandom.alphanumeric(32).upcase
        filtered_chars = raw_id.chars.reject do |char|
          AMBIGUOUS_CHARS.include?(char)
        end
        id = filtered_chars.first(ID_LENGTH).join
        next if id.length < ID_LENGTH
        break id unless exists?({id: id}.merge(scope_conditions))
      end
    end

    sig do
      params(
        count: Integer,
        scope_conditions: T::Hash[T.untyped, T.untyped]
      ).returns(T::Array[String])
    end
    def generate_random_ids(count, scope_conditions = {})
      return [] if count <= 0

      needed = count
      generated_ids = []

      while needed > 0
        # Generate a batch of candidate IDs
        candidates = needed.times.map { generate_single_id_string }

        # Check which ones already exist (single DB query)
        existing = where(id: candidates).pluck(:id)
        new_ids = candidates - existing

        generated_ids.concat(new_ids)
        needed -= new_ids.length
      end

      generated_ids.first(count)
    end

    sig { returns(String) }
    def generate_single_id_string
      loop do
        raw_id = SecureRandom.alphanumeric(32).upcase
        filtered_chars = raw_id.chars.reject do |char|
          AMBIGUOUS_CHARS.include?(char)
        end
        id = filtered_chars.first(ID_LENGTH).join
        return id if id.length == ID_LENGTH
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
