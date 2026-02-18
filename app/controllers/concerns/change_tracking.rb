# typed: true
# frozen_string_literal: true

module ChangeTracking
  extend ActiveSupport::Concern
  extend T::Sig

  private

  sig do
    params(
      previous_attributes: T::Hash[String, T.untyped],
      current_attributes: T::Hash[String, T.untyped],
      changed_keys: T::Array[T.any(String, Symbol)]
    ).returns(T.nilable(T::Hash[String, T::Hash[String, T.untyped]]))
  end
  def calculate_changes(previous_attributes, current_attributes, changed_keys)
    changes = {}

    changed_keys.map(&:to_s).each do |key|
      previous_value = previous_attributes[key]
      current_value = current_attributes[key]

      next unless previous_value != current_value

      changes[key] = {
        "from" => previous_value,
        "to" => current_value
      }
    end

    changes.presence
  end
end
