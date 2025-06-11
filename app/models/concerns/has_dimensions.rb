# Shared concern for models that have dimension fields
module HasDimensions
  extend ActiveSupport::Concern

  included do
    # Basic dimension validations
    validates :width, :length, :height,
      presence: true,
      numericality: {greater_than: 0, less_than: 200},
      allow_nil: true # Allow nil for optional dimensions

    # Optional dimension validations
    validates :num_low_anchors, :num_high_anchors, :exit_number,
      :users_at_1000mm, :users_at_1200mm, :users_at_1500mm, :users_at_1800mm,
      numericality: {only_integer: true, greater_than_or_equal_to: 0},
      allow_nil: true

    validates :rope_size, :slide_platform_height, :slide_wall_height,
      :runout_value, :slide_first_metre_height,
      :slide_beyond_first_metre_height, :stitch_length, :unit_pressure_value,
      :blower_tube_length, :step_size_value, :fall_off_height_value,
      :trough_depth_value, :trough_width_value, :containing_wall_height,
      :platform_height, :tallest_user_height, :play_area_length,
      :play_area_width, :negative_adjustment,
      numericality: {greater_than_or_equal_to: 0},
      allow_nil: true

    # Scopes for dimensional queries
    scope :within_dimensions, ->(width, length, height) {
      where("width <= ? AND length <= ? AND height <= ?", width, length, height)
    }

    scope :by_area_range, ->(min_area, max_area) {
      where("(width * length) BETWEEN ? AND ?", min_area, max_area)
    }
  end

  # Instance methods
  def dimensions
    return nil unless width.present? && length.present? && height.present?

    # Format dimensions nicely - show integers without decimals
    w = (width % 1 == 0) ? width.to_i : width
    l = (length % 1 == 0) ? length.to_i : length
    h = (height % 1 == 0) ? height.to_i : height

    "#{w}m × #{l}m × #{h}m"
  end

  def area
    width * length if width.present? && length.present?
  end

  def volume
    return unless dimensions_present?

    width * length * height
  end

  # Attribute groups for better organization and DRY code
  def basic_attributes
    {
      width:, length:, height:,
      width_comment:, length_comment:, height_comment:
    }
  end

  def anchorage_attributes
    {
      num_low_anchors:, num_high_anchors:,
      num_anchors_comment: combined_anchor_comments
    }
  end

  def enclosed_attributes
    {exit_number:, exit_number_comment:}
  end

  def materials_attributes
    {rope_size:, rope_size_comment:}
  end

  def slide_attributes
    {
      slide_platform_height:, slide_wall_height:, runout_value:,
      slide_first_metre_height:, slide_beyond_first_metre_height:,
      slide_permanent_roof:, slide_platform_height_comment:,
      slide_wall_height_comment:, slide_first_metre_height_comment:,
      slide_beyond_first_metre_height_comment:,
      slide_permanent_roof_comment:,
      runout_comment: runout_value_comment
    }
  end

  def structure_attributes
    {
      stitch_length:, unit_pressure_value:, blower_tube_length:,
      step_size_value:, fall_off_height_value:, trough_depth_value:,
      trough_width_value:
    }
  end

  def user_height_attributes
    user_height_data_attributes.merge(user_height_comment_attributes)
  end

  def copyable_attributes
    # Use reflection-based approach to get all copyable attributes
    copyable_attrs = copyable_attributes_via_reflection

    # Create a hash with current values for these attributes
    copyable_attrs.each_with_object({}) do |attr, hash|
      if respond_to?(attr)
        hash[attr] = send(attr)
      end
    end.compact
  end

  # Alias for backward compatibility
  def dimension_attributes
    copyable_attributes
  end

  def has_slide_attributes?
    slide_platform_height.present? || slide_wall_height.present? ||
      runout_value.present? || slide_first_metre_height.present? ||
      slide_beyond_first_metre_height.present?
  end

  def has_structure_attributes?
    stitch_length.present? ||
      unit_pressure_value.present? || blower_tube_length.present? ||
      step_size_value.present? || fall_off_height_value.present? ||
      trough_depth_value.present? || trough_width_value.present?
  end

  def has_user_height_attributes?
    containing_wall_height.present? || platform_height.present? ||
      tallest_user_height.present? || play_area_length.present? ||
      play_area_width.present?
  end

  def has_anchorage_attributes?
    num_low_anchors.present? || num_high_anchors.present?
  end

  def total_anchors
    (num_low_anchors || 0) + (num_high_anchors || 0)
  end

  def max_user_capacity
    user_capacity_values.compact.max || 0
  end

  # Copy all attributes from another object (dimensions, comments, flags, etc.)
  def copy_attributes_from(source)
    copy_shared_attributes(source)
  end

  # Alias for backward compatibility
  def copy_dimensions_from(source)
    copy_attributes_from(source)
  end

  # Copy all shared attributes from another object using reflection
  def copy_shared_attributes(source)
    return unless source
    return unless source.respond_to?(:attributes)

    # Get all attribute names from the source object
    source_attributes = source.attributes.keys

    # Get all setter methods on this object
    my_setters = methods.grep(/=$/).map { |m| m.to_s.chomp("=") }

    # Find common attributes (source has attribute and we have setter)
    common_attributes = source_attributes & my_setters

    # Copy each copyable attribute
    (common_attributes - excluded_copyable_attributes).each do |attr|
      value = source.send(attr)
      send("#{attr}=", value) if should_copy_value?(value, source, attr)
    end
  end

  # Get list of copyable attributes using reflection
  def copyable_attributes_via_reflection
    # Get column names from this model
    my_columns = self.class.column_names

    # Get column names from the other model we copy to/from
    other_columns = if instance_of?(Unit) && defined?(Inspection)
      Inspection.column_names
    elsif instance_of?(Inspection) && defined?(Unit)
      Unit.column_names
    else
      # Fallback to just this model's columns
      my_columns
    end

    # Find common attributes
    common_attributes = my_columns & other_columns

    # Remove excluded attributes
    (common_attributes - excluded_copyable_attributes).map(&:to_sym)
  end

  # Check if any copyable attribute has changed
  def attributes_changed?
    copyable_attributes.keys.any? { |attr| send("#{attr}_changed?") }
  end

  # Alias for backward compatibility
  def dimension_changed?
    attributes_changed?
  end

  # Assessment pre-filling methods (for inspections)
  def build_assessments_with_attributes
    return unless respond_to?(:user_height_assessment)

    build_user_height_assessment_with_attributes unless user_height_assessment
    build_slide_assessment_with_attributes unless slide_assessment
    build_structure_assessment_with_attributes unless structure_assessment
    build_anchorage_assessment_with_attributes unless anchorage_assessment
    build_materials_assessment_with_attributes unless materials_assessment
    build_fan_assessment unless fan_assessment
    build_enclosed_assessment_with_attributes unless enclosed_assessment
  end

  private

  # Attributes that should never be copied between models
  def excluded_copyable_attributes
    %w[
      id created_at updated_at user_id unit_id inspection_id
      unique_report_number status passed comments recommendations
      general_notes inspector_signature signature_timestamp
      pdf_last_accessed_at inspection_date inspection_location
      name serial manufacturer model owner description
      manufacture_date condition notes serial_number
    ]
  end

  def build_user_height_assessment_with_attributes
    build_user_height_assessment(user_height_attributes.compact)
  end

  def build_slide_assessment_with_attributes
    build_slide_assessment(slide_attributes.compact)
  end

  def build_structure_assessment_with_attributes
    build_structure_assessment(structure_attributes.compact)
  end

  def build_anchorage_assessment_with_attributes
    build_anchorage_assessment(anchorage_attributes.compact)
  end

  def build_materials_assessment_with_attributes
    build_materials_assessment(materials_attributes.compact)
  end

  def build_enclosed_assessment_with_attributes
    build_enclosed_assessment(enclosed_attributes.compact)
  end

  private

  def combined_anchor_comments
    comments = [num_low_anchors_comment, num_high_anchors_comment]
    comments.compact.join("; ").presence
  end

  def user_capacity_values
    [users_at_1000mm, users_at_1200mm, users_at_1500mm, users_at_1800mm]
  end

  def should_copy_value?(value, source, attr)
    value.present? || source.send("#{attr}?") == false
  end

  def dimensions_present?
    width.present? && length.present? && height.present?
  end

  def user_height_data_attributes
    {
      containing_wall_height:, platform_height:, tallest_user_height:,
      users_at_1000mm:, users_at_1200mm:, users_at_1500mm:,
      users_at_1800mm:, play_area_length:, play_area_width:,
      negative_adjustment:, permanent_roof:
    }
  end

  def user_height_comment_attributes
    {
      containing_wall_height_comment:, platform_height_comment:,
      permanent_roof_comment:, play_area_length_comment:,
      play_area_width_comment:, negative_adjustment_comment:
    }
  end

  module ClassMethods
    # Find units/inspections with similar dimensions
    def with_similar_dimensions(reference, tolerance: 0.1)
      return none unless valid_reference_dimensions?(reference)

      width_range = dimension_range(reference.width, tolerance)
      length_range = dimension_range(reference.length, tolerance)
      height_range = dimension_range(reference.height, tolerance)

      where(width: width_range, length: length_range, height: height_range)
    end

    private

    def valid_reference_dimensions?(reference)
      reference.respond_to?(:width) && reference.width.present?
    end

    def dimension_range(value, tolerance)
      (value * (1 - tolerance))..(value * (1 + tolerance))
    end
  end
end
