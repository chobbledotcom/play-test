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

    validates :rope_size, :slide_platform_height, :slide_wall_height, :runout_value,
      :slide_first_metre_height, :slide_beyond_first_metre_height,
      :stitch_length, :unit_pressure_value,
      :blower_tube_length, :step_size_value, :fall_off_height_value,
      :trough_depth_value, :trough_width_value, :containing_wall_height,
      :platform_height, :user_height, :play_area_length, :play_area_width,
      :negative_adjustment,
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
    width * length * height if width.present? && length.present? && height.present?
  end

  def dimension_attributes
    {
      # Basic dimensions
      width: width,
      length: length,
      height: height,
      width_comment: width_comment,
      length_comment: length_comment,
      height_comment: height_comment,

      # Anchorage
      num_low_anchors: num_low_anchors,
      num_high_anchors: num_high_anchors,
      num_low_anchors_comment: num_low_anchors_comment,
      num_high_anchors_comment: num_high_anchors_comment,

      # Enclosed
      exit_number: exit_number,
      exit_number_comment: exit_number_comment,

      # Materials
      rope_size: rope_size,
      rope_size_comment: rope_size_comment,

      # Slide
      slide_platform_height: slide_platform_height,
      slide_wall_height: slide_wall_height,
      runout_value: runout_value,
      slide_first_metre_height: slide_first_metre_height,
      slide_beyond_first_metre_height: slide_beyond_first_metre_height,
      slide_permanent_roof: slide_permanent_roof,
      slide_platform_height_comment: slide_platform_height_comment,
      slide_wall_height_comment: slide_wall_height_comment,
      runout_value_comment: runout_value_comment,
      slide_first_metre_height_comment: slide_first_metre_height_comment,
      slide_beyond_first_metre_height_comment: slide_beyond_first_metre_height_comment,
      slide_permanent_roof_comment: slide_permanent_roof_comment,

      # Structure
      stitch_length: stitch_length,
      unit_pressure_value: unit_pressure_value,
      blower_tube_length: blower_tube_length,
      step_size_value: step_size_value,
      fall_off_height_value: fall_off_height_value,
      trough_depth_value: trough_depth_value,
      trough_width_value: trough_width_value,

      # User height
      containing_wall_height: containing_wall_height,
      platform_height: platform_height,
      user_height: user_height,
      users_at_1000mm: users_at_1000mm,
      users_at_1200mm: users_at_1200mm,
      users_at_1500mm: users_at_1500mm,
      users_at_1800mm: users_at_1800mm,
      play_area_length: play_area_length,
      play_area_width: play_area_width,
      negative_adjustment: negative_adjustment,
      permanent_roof: permanent_roof,
      containing_wall_height_comment: containing_wall_height_comment,
      platform_height_comment: platform_height_comment,
      permanent_roof_comment: permanent_roof_comment,
      play_area_length_comment: play_area_length_comment,
      play_area_width_comment: play_area_width_comment,
      negative_adjustment_comment: negative_adjustment_comment
    }.compact
  end

  def has_slide_dimensions?
    slide_platform_height.present? || slide_wall_height.present? ||
      runout_value.present? || slide_first_metre_height.present? ||
      slide_beyond_first_metre_height.present?
  end

  def has_structure_dimensions?
    stitch_length.present? ||
      unit_pressure_value.present? || blower_tube_length.present? ||
      step_size_value.present? || fall_off_height_value.present? ||
      trough_depth_value.present? || trough_width_value.present?
  end

  def has_user_height_dimensions?
    containing_wall_height.present? || platform_height.present? ||
      user_height.present? || play_area_length.present? ||
      play_area_width.present?
  end

  def has_anchorage_dimensions?
    num_low_anchors.present? || num_high_anchors.present?
  end

  def total_anchors
    (num_low_anchors || 0) + (num_high_anchors || 0)
  end

  def max_user_capacity
    [users_at_1000mm, users_at_1200mm, users_at_1500mm, users_at_1800mm].compact.max || 0
  end

  # Copy all dimension attributes from another object
  def copy_dimensions_from(source)
    copy_values_from(source)
  end

  # Copy all shared attributes from another object
  def copy_values_from(source)
    return unless source
    return unless source.respond_to?(:attributes)

    # Get all attribute names from the source object
    source_attributes = source.attributes.keys

    # Get all setter methods on this object
    my_setters = methods.grep(/=$/).map { |m| m.to_s.chomp("=") }

    # Find common attributes (source has the attribute and we have a setter for it)
    common_attributes = source_attributes & my_setters

    # Exclude certain attributes we never want to copy
    excluded_attributes = %w[id created_at updated_at user_id unit_id inspection_id]

    # Copy each common attribute
    (common_attributes - excluded_attributes).each do |attr|
      value = source.send(attr)
      send("#{attr}=", value) if value.present? || source.send("#{attr}?") == false
    end
  end

  # Check if any dimension has changed
  def dimension_changed?
    dimension_attributes.keys.any? { |attr| send("#{attr}_changed?") }
  end

  module ClassMethods
    # Find units/inspections with similar dimensions
    def with_similar_dimensions(reference, tolerance: 0.1)
      return none unless reference.respond_to?(:width) && reference.width.present?

      width_range = (reference.width * (1 - tolerance))..(reference.width * (1 + tolerance))
      length_range = (reference.length * (1 - tolerance))..(reference.length * (1 + tolerance))
      height_range = (reference.height * (1 - tolerance))..(reference.height * (1 + tolerance))

      where(width: width_range, length: length_range, height: height_range)
    end

    # Statistical methods for dimensions
    def dimension_statistics
      {
        width: {avg: average(:width), min: minimum(:width), max: maximum(:width)},
        length: {avg: average(:length), min: minimum(:length), max: maximum(:length)},
        height: {avg: average(:height), min: minimum(:height), max: maximum(:height)},
        area: {avg: average("width * length"), min: minimum("width * length"), max: maximum("width * length")}
      }
    end
  end
end
