module FormConfigurable
  extend ActiveSupport::Concern

  class_methods do
    def form_fields(user: nil)
      @form_config ||= load_form_config_from_yaml
    end

    def load_form_config_from_yaml
      # Remove namespace and use just the class name
      file_name = name.demodulize.underscore
      config_path = Rails.root.join("config/forms/#{file_name}.yml")
      yaml_content = YAML.load_file(config_path)
      yaml_content["form_fields"].map(&:deep_symbolize_keys)
    end
  end
end
