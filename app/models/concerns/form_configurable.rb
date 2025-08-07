# typed: true
# frozen_string_literal: true

module FormConfigurable
  extend ActiveSupport::Concern
  extend T::Sig

  class_methods do
    extend T::Sig

    sig do
      params(user: T.nilable(User))
        .returns(T::Array[T::Hash[Symbol, T.untyped]])
    end
    def form_fields(user: nil)
      @form_config ||= load_form_config_from_yaml
    end

    sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
    def load_form_config_from_yaml
      # Remove namespace and use just the class name
      file_name = name.demodulize.underscore

      # Check main app first, then gem
      config_path = Rails.root.join("config/forms/#{file_name}.yml")
      unless File.exist?(config_path)
        # Try loading from the gem
        if defined?(En14960Assessments::Engine)
          gem_path = En14960Assessments::Engine.root
            .join("config/forms/#{file_name}.yml")
          config_path = gem_path if File.exist?(gem_path)
        end
      end

      yaml_content = YAML.load_file(config_path)
      yaml_content["form_fields"].map(&:deep_symbolize_keys)
    end
  end
end
