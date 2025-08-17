# typed: strict
# frozen_string_literal: true

require "rails_helper"
require "sorbet-runtime"

# System columns that should be excluded from validation
SYSTEM_COLUMNS = %i[inspection_id created_at updated_at].freeze

# Assessment types to validate
ASSESSMENT_TYPES = %w[
  anchorage_assessment
  enclosed_assessment
  fan_assessment
  materials_assessment
  slide_assessment
  structure_assessment
  user_height_assessment
].freeze

# Define expected partials for different column types
PARTIAL_TYPE_MAPPINGS = {
  # Boolean columns
  boolean: %i[pass_fail checkbox yes_no_radio pass_fail_comment
    yes_no_radio_comment],
  # Integer columns (includes pass/fail/NA values as 0/1/2)
  integer: %i[number integer_comment number_pass_fail_comment
    number_pass_fail_na_comment pass_fail_na_comment],
  # Decimal columns (we use decimal, not float)
  decimal: %i[number decimal_comment number_pass_fail_comment
    number_pass_fail_na_comment],
  # Text/String columns
  text: %i[text_area comment pass_fail_comment pass_fail_na_comment
    radio_comment yes_no_radio_comment text_field],
  string: %i[text_field text_area comment pass_fail_comment
    pass_fail_na_comment radio_comment yes_no_radio_comment]
}.freeze

# Define allowed attributes for each partial type
PARTIAL_ALLOWED_ATTRIBUTES = {
  # Number fields can have step, min, max
  number: %i[step min max],
  number_pass_fail_comment: %i[step min max],
  number_pass_fail_na_comment: %i[step min max],
  decimal_comment: %i[step min max],
  integer_comment: %i[step min max add_not_applicable],
  # Most partials don't allow any attributes
  text_field: [],
  text_area: [],
  pass_fail: [],
  pass_fail_comment: [],
  pass_fail_na_comment: [],
  checkbox: [],
  yes_no_radio: [],
  yes_no_radio_comment: [],
  comment: [],
  radio_comment: []
}.freeze

RSpec.describe "Form YAML Database Schema Validation" do
  extend T::Sig
  include FormHelpers

  # Helper to get all fields from form config - returns Symbols
  sig do
    params(
      form_config: T.nilable(T::Array[T::Hash[Symbol, T.untyped]])
    ).returns(T::Array[Symbol])
  end
  define_method(:get_all_form_fields) do |form_config|
    return [] unless form_config

    fields = T.let([], T::Array[Symbol])
    form_config.each do |fieldset|
      fieldset[:fields].each do |field_config|
        field = field_config[:field]
        partial = field_config[:partial]

        # Only add base field if partial doesn't start with pass_fail
        # (for pass_fail partials, only the _pass field exists in DB)
        unless partial.start_with?("pass_fail")
          fields << field
        end

        composite_fields = ChobbleForms::FieldUtils
          .get_composite_fields(field, partial)
        fields.concat(composite_fields)
      end
    end
    fields
  end

  # Helper to get database columns for an assessment - returns Symbols
  sig { params(table_name: String).returns(T::Array[Symbol]) }
  define_method(:get_database_columns) do |table_name|
    ActiveRecord::Base.connection.columns(table_name).map(&:name).map(&:to_sym)
  end

  describe "Task 1: Database Column Coverage" do
    it "includes all database columns in form YAML files" do
      missing_fields_by_assessment = {}

      ASSESSMENT_TYPES.each do |assessment_type|
        table_name = assessment_type.pluralize
        config_path = Rails.root.join("config/forms/#{assessment_type}.yml")
        yaml_content = get_form_config(config_path)
        form_config = yaml_content[:form_fields]

        # Get database columns excluding system columns
        db_columns = get_database_columns(table_name) - SYSTEM_COLUMNS

        # Get all fields defined in form
        form_fields = get_all_form_fields(form_config)

        # Find missing fields
        missing_fields = db_columns - form_fields

        # For composite fields, we need to check if base field is covered
        # e.g., if "num_low_anchors_pass" and "num_low_anchors_comment" exist,
        # they might be covered by "num_low_anchors" with a composite partial
        missing_fields = missing_fields.reject do |field|
          # Check if this is a _pass or _comment field that has a base field
          if ChobbleForms::FieldUtils.is_composite_field?(field)
            base_field = ChobbleForms::FieldUtils
              .strip_field_suffix(field)
            form_fields.include?(base_field)
          else
            false
          end
        end

        if missing_fields.any?
          missing_fields_by_assessment[assessment_type] = missing_fields
        end
      end

      if missing_fields_by_assessment.any?
        error_message = "The following database columns are missing "
        error_message += "from form YAML files:\n\n"
        missing_fields_by_assessment.each do |assessment, fields|
          error_message += "#{assessment}:\n"
          fields.each do |field|
            error_message += "  - #{field}\n"
          end
          error_message += "\n"
        end

        expect(missing_fields_by_assessment).to be_empty, error_message
      end
    end
  end

  describe "Task 2: Fieldset Uniqueness" do
    it "has unique fieldset legend keys within each form" do
      duplicate_legends_by_assessment = {}

      ASSESSMENT_TYPES.each do |assessment_type|
        config_path = Rails.root.join("config/forms/#{assessment_type}.yml")
        yaml_content = get_form_config(config_path)
        form_config = yaml_content[:form_fields]

        # Get all legend keys
        legend_keys = form_config.map { |fieldset| fieldset[:legend_i18n_key] }

        # Find duplicates
        legend_counts = legend_keys.tally
        duplicates = legend_counts.select { |_, count| count > 1 }.keys

        if duplicates.any?
          duplicate_legends_by_assessment[assessment_type] = duplicates
        end
      end

      if duplicate_legends_by_assessment.any?
        error_message = "The following forms have duplicate "
        error_message += "fieldset legends:\n\n"
        duplicate_legends_by_assessment.each do |assessment, legends|
          error_message += "#{assessment}:\n"
          legends.each do |legend|
            error_message += "  - #{legend}\n"
          end
          error_message += "\n"
        end

        expect(duplicate_legends_by_assessment).to be_empty, error_message
      end
    end
  end

  describe "Task 3: Partial Type Validation" do
    it "uses appropriate partials for database column types" do
      errors = []

      ASSESSMENT_TYPES.each do |assessment_type|
        table_name = assessment_type.pluralize
        config_path = Rails.root.join("config/forms/#{assessment_type}.yml")
        yaml_content = get_form_config(config_path)
        form_config = yaml_content[:form_fields]

        # Get column types from database
        columns = ActiveRecord::Base.connection.columns(table_name)
        column_types = columns.each_with_object({}) do |col, hash|
          hash[col.name] = col.type
        end

        form_config.each do |fieldset|
          fieldset[:fields].each do |field_config|
            field = field_config[:field]
            partial = field_config[:partial]

            # Determine which database fields need to exist
            # based on partial name
            required_fields = []
            partial_str = partial.to_s

            # If partial doesn't start with pass_fail, it needs the base field
            unless partial_str.start_with?("pass_fail")
              required_fields << field.to_s
            end

            # If partial contains pass_fail, it needs the _pass field
            if partial_str.include?("pass_fail")
              required_fields << "#{field}_pass"
            end

            # If partial contains comment, it needs the _comment field
            if partial_str.include?("comment")
              required_fields << "#{field}_comment"
            end

            # Check if all required fields exist in database
            missing_fields = required_fields.reject { |f| column_types[f] }
            if missing_fields.any?
              errors << <<~MSG
                #{assessment_type}: #{partial} partial with field '#{field}'
                  missing database columns: #{missing_fields.join(", ")}
              MSG
              next
            end

            # For type checking, use the primary field
            # (base field if it exists, otherwise _pass field)
            primary_field = required_fields.find { |f|
              !f.end_with?("_comment")
            } || required_fields.first
            column_type = column_types[primary_field]
            allowed_partials = PARTIAL_TYPE_MAPPINGS[column_type] || []

            # For composite partials, check the base field type
            if %i[pass_fail_comment pass_fail_na_comment].include?(partial)
              # These handle boolean _pass fields
              pass_field = "#{field}_pass"
              if column_types[pass_field] == :boolean
                next # This is valid
              end
            end

            next if allowed_partials.include?(partial)

            errors << <<~MSG
              #{assessment_type}:
                Field '#{field}' (#{column_type}) uses '#{partial}' partial
                Allowed partials: #{allowed_partials.join(", ")}
            MSG
          end
        end
      end

      if errors.any?
        expect(errors).to be_empty, <<~MSG
          The following fields have validation errors:

          #{errors.join("\n")}
        MSG
      end
    end
  end

  describe "Task 4: No Extra Fields" do
    it "does not define fields that don't exist in the database" do
      errors = []

      ASSESSMENT_TYPES.each do |assessment_type|
        table_name = assessment_type.pluralize
        config_path = Rails.root.join("config/forms/#{assessment_type}.yml")
        yaml_content = get_form_config(config_path)
        form_config = yaml_content[:form_fields]

        # Get all database columns
        db_columns = get_database_columns(table_name)

        # Get all fields from form (including composite fields)
        form_fields = get_all_form_fields(form_config)

        # Find fields that exist in form but not in database
        extra_fields = form_fields - db_columns

        next unless extra_fields.any?

        errors << <<~MSG
          #{assessment_type}:
            Extra fields defined in form but not in database:
            #{extra_fields.map { |f| "  - #{f}" }.join("\n")}
        MSG
      end

      if errors.any?
        expect(errors).to be_empty, <<~MSG
          The following forms define fields that don't exist in the database:

          #{errors.join("\n")}
        MSG
      end
    end
  end

  describe "Task 5: Composite Field Validation" do
    it "has matching database fields for composite partials" do
      errors = []

      ASSESSMENT_TYPES.each do |assessment_type|
        table_name = assessment_type.pluralize
        config_path = Rails.root.join("config/forms/#{assessment_type}.yml")
        yaml_content = get_form_config(config_path)
        form_config = yaml_content[:form_fields]

        # Get all database columns
        db_columns = get_database_columns(table_name)

        form_config.each do |fieldset|
          fieldset[:fields].each do |field_config|
            field = field_config[:field]
            partial = field_config[:partial]

            # Check composite fields have all required columns
            case partial
            when "pass_fail_comment", "pass_fail_na_comment"
              if field.end_with?("_pass")
                # Field ending in _pass should have matching _comment field
                base_field = field.gsub(/_pass$/, "")
                comment_field = "#{base_field}_comment"
              else
                # Base field should have both _pass and _comment
                pass_field = "#{field}_pass"
                comment_field = "#{field}_comment"
                unless db_columns.include?(pass_field)
                  errors << <<~MSG
                    #{assessment_type}: #{pass_field} missing for #{field}
                  MSG
                end
              end
              unless db_columns.include?(comment_field)
                errors << <<~MSG
                  #{assessment_type}: #{comment_field} missing for #{field}
                MSG
              end
            when "number_pass_fail_comment", "number_pass_fail_na_comment"
              # Base field should exist, plus _pass and _comment
              unless db_columns.include?(field)
                errors << <<~MSG
                  #{assessment_type}: #{field} missing
                MSG
              end
              pass_field = "#{field}_pass"
              comment_field = "#{field}_comment"
              unless db_columns.include?(pass_field)
                errors << <<~MSG
                  #{assessment_type}: #{pass_field} missing for #{field}
                MSG
              end
              unless db_columns.include?(comment_field)
                errors << <<~MSG
                  #{assessment_type}: #{comment_field} missing for #{field}
                MSG
              end
            when "decimal_comment", "integer_comment", "yes_no_radio_comment"
              # Base field should exist, plus _comment
              unless db_columns.include?(field)
                errors << <<~MSG
                  #{assessment_type}: #{field} missing
                MSG
              end
              comment_field = "#{field}_comment"
              unless db_columns.include?(comment_field)
                errors << <<~MSG
                  #{assessment_type}: #{comment_field} missing for #{field}
                MSG
              end
            end
          end
        end
      end

      if errors.any?
        expect(errors).to be_empty, <<~MSG
          Composite field validation errors:

          #{errors.join("\n")}
        MSG
      end
    end
  end

  describe "Field Attributes Validation" do
    it "only uses allowed attributes for each partial type" do
      errors = []

      ASSESSMENT_TYPES.each do |assessment_type|
        config_path = Rails.root.join("config/forms/#{assessment_type}.yml")
        yaml_content = get_form_config(config_path)
        form_config = yaml_content[:form_fields]

        form_config.each do |fieldset|
          fieldset[:fields].each do |field_config|
            field = field_config[:field]
            partial = field_config[:partial]
            attributes = field_config[:attributes] || {}

            # Get allowed attributes for this partial
            allowed = PARTIAL_ALLOWED_ATTRIBUTES[partial]

            # Skip if partial not in our list (might be custom)
            next unless allowed

            # Check for disallowed attributes
            disallowed = attributes.keys - allowed
            next unless disallowed.any?

            disallowed_attrs = disallowed.join(", ")
            errors << <<~MSG
              #{assessment_type}: #{field} (#{partial}) has disallowed
              attributes: #{disallowed_attrs}
            MSG
          end
        end
      end

      if errors.any?
        expect(errors).to be_empty, <<~MSG
          Field attribute validation errors:

          #{errors.join("\n")}
        MSG
      end
    end
  end
end
