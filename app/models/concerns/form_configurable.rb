# typed: true
# frozen_string_literal: true

module FormConfigurable
  extend ActiveSupport::Concern
  extend T::Sig

  class_methods do
    extend T::Sig

    sig { params(user: T.nilable(User)).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
    def form_fields(user: nil)
      @form_fields ||= load_form_config_from_yaml
    end

    sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
    def load_form_config_from_yaml
      file_name = name.demodulize.underscore
      config_path = Rails.root.join("config/forms/#{file_name}.yml")
      yaml_content = YAML.load_file(config_path)
      yaml_content.deep_symbolize_keys!
    end
  end
end
