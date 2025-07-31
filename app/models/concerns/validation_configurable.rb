module ValidationConfigurable
  extend ActiveSupport::Concern

  included do
    # Apply validations when the concern is included
    if ancestors.include?(FormConfigurable)
      apply_form_validations
    end
  end

  class_methods do
    def apply_form_validations
      form_config = begin
        form_fields
      rescue
        nil
      end
      return unless form_config

      form_config.each do |section|
        next unless section[:fields]

        section[:fields].each do |field_config|
          apply_validation_for_field(field_config)
        end
      end
    end

    private

    def apply_validation_for_field(field_config)
      field = field_config[:field]
      attributes = field_config[:attributes] || {}
      partial = field_config[:partial]

      return unless field

      if attributes[:required]
        validates field, presence: true
      end

      case partial
      when "decimal_comment", "decimal"
        apply_decimal_validation(field, attributes)
      when "number", "number_pass_fail_na_comment"
        apply_number_validation(field, attributes)
      end
    end

    def apply_decimal_validation(field, attributes)
      options = build_numericality_options(attributes)
      validates field, numericality: options, allow_blank: true
    end

    def apply_number_validation(field, attributes)
      options = build_numericality_options(attributes)
      options[:only_integer] = true
      validates field, numericality: options, allow_blank: true
    end

    def build_numericality_options(attributes)
      options = {}

      if attributes[:min]
        options[:greater_than_or_equal_to] = attributes[:min]
      end

      if attributes[:max]
        options[:less_than_or_equal_to] = attributes[:max]
      end

      options
    end
  end
end
