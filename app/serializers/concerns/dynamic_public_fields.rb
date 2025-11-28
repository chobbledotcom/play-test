# typed: strict
# frozen_string_literal: true

module DynamicPublicFields
  extend T::Sig
  extend T::Helpers

  mixes_in_class_methods(ClassMethods)

  module ClassMethods
    extend T::Sig

    sig { returns(T.nilable(T::Boolean)) }
    attr_accessor :fields_defined

    sig {
      params(
        model_class: T.untyped,
        date_fields: T::Array[Symbol]
      ).void
    }
    def define_public_fields_for(model_class, date_fields: [])
      return if @fields_defined

      model_class.column_name_syms.each do |column|
        next if PublicFieldFiltering::EXCLUDED_FIELDS.include?(column)

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
