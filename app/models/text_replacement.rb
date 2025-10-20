# typed: true
# frozen_string_literal: true

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
class TextReplacement < ApplicationRecord
  extend T::Sig

  validates :i18n_key, presence: true, uniqueness: true
  validates :value, presence: true

  # Returns all i18n keys available in the application
  sig { returns(T::Array[String]) }
  def self.available_i18n_keys
    keys = []
    I18n.backend.send(:translations).each do |locale, translations|
      keys.concat(flatten_keys(locale.to_s, translations))
    end
    keys.sort
  end

  # Recursively flattens nested i18n hash into dot-notation keys
  sig {
    params(
      prefix: String,
      hash: T::Hash[T.untyped, T.untyped]
    ).returns(T::Array[String])
  }
  def self.flatten_keys(prefix, hash)
    keys = []
    hash.each do |key, value|
      full_key = "#{prefix}.#{key}"
      if value.is_a?(Hash)
        keys.concat(flatten_keys(full_key, value))
      else
        keys << full_key
      end
    end
    keys
  end

  # Returns a nested hash structure for displaying in tree view
  sig { returns(T::Hash[String, T.untyped]) }
  def self.tree_structure
    all.each_with_object({}) do |replacement, tree|
      parts = replacement.i18n_key.split(".")
      current = tree
      parts.each_with_index do |part, index|
        current[part] ||= {}
        if index == parts.length - 1
          current[part][:_value] = replacement.value
          current[part][:_id] = replacement.id
        else
          current = current[part]
        end
      end
    end
  end
end
