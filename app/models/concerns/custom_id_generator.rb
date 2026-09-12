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

    sig { returns(String) }
    def generate_random_id
      loop do
        id = generate_single_id_string
        break id unless exists?(id: id)
      end
    end

    sig { params(count: Integer).returns(T::Array[String]) }
    def generate_random_ids(count)
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
        id = candidate_id_chars
        return id if id.length == ID_LENGTH
      end
    end

    private

    sig { returns(String) }
    def candidate_id_chars
      raw_id = SecureRandom.alphanumeric(32).upcase
      raw_id.chars
        .reject { |char| AMBIGUOUS_CHARS.include?(char) }
        .first(ID_LENGTH)
        .join
    end
  end

  private

  sig { void }
  def generate_custom_id
    self.id = self.class.generate_random_id
  end
end
