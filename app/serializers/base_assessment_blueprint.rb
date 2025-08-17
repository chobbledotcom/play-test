# typed: false
# frozen_string_literal: true

class BaseAssessmentBlueprint < Blueprinter::Base
  # Define public fields from model columns excluding system fields
  def self.public_fields_for(klass)
    klass.column_name_syms - PublicFieldFiltering::EXCLUDED_FIELDS
  end

  # Use transformer to format dates consistently
  transform JsonDateTransformer
end
