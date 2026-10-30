# typed: false
# frozen_string_literal: true

module DynamicPublicFields
  extend ActiveSupport::Concern

  class_methods do
    # Declares which model and date fields to use for dynamic field generation.
    # Also overrides render to trigger field definition on first call.
    def dynamic_fields_for(model_class, date_fields: [], excluded_fields: [],
      revision_fields: [])
      @dynamic_model_class = model_class
      @dynamic_date_fields = T.let(date_fields, T::Array[Symbol])
      @dynamic_excluded_fields = excluded_fields
      @dynamic_revision_fields = revision_fields
    end

    def render(object, options = {})
      define_public_fields_for(
        @dynamic_model_class, date_fields: @dynamic_date_fields
      )
      super
    end

    def define_public_fields_for(model_class, date_fields: [])
      return if @fields_defined

      model_class.column_name_syms.each do |column|
        next if PublicFieldFiltering::EXCLUDED_FIELDS.include?(column)
        next if @dynamic_excluded_fields.include?(column)

        if @dynamic_revision_fields.include?(column)
          field column, if: ->(_name, record, _options) {
            record.current_checklist?
          }
          next
        end

        if date_fields.include?(column)
          field column do |record|
            value = record.send(column)
            value&.strftime(JsonDateTransformer::API_DATE_FORMAT)
          end
        else
          field column
        end
      end
      @fields_defined = true
    end
  end
end
