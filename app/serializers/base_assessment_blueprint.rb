# typed: strict
# frozen_string_literal: true

class BaseAssessmentBlueprint < Blueprinter::Base
  extend T::Sig

  # Define public fields from model columns excluding system fields
  sig { params(klass: T.class_of(ApplicationRecord)).returns(T::Array[Symbol]) }
  def self.public_fields_for(klass)
    klass.column_name_syms - PublicFieldFiltering::EXCLUDED_FIELDS
  end

  # Use transformer to format dates consistently
  transform JsonDateTransformer
end
