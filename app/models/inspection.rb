class Inspection < ApplicationRecord
  include CustomIdGenerator

  PASS_FAIL_NA = {fail: 0, pass: 1, na: 2}.freeze

  enum :inspection_type, {
    bouncy_castle: "BOUNCY_CASTLE",
    bouncing_pillow: "BOUNCING_PILLOW"
  }

  CASTLE_ASSESSMENT_TYPES = {
    user_height_assessment: Assessments::UserHeightAssessment,
    slide_assessment: Assessments::SlideAssessment,
    structure_assessment: Assessments::StructureAssessment,
    anchorage_assessment: Assessments::AnchorageAssessment,
    materials_assessment: Assessments::MaterialsAssessment,
    enclosed_assessment: Assessments::EnclosedAssessment,
    fan_assessment: Assessments::FanAssessment
  }.freeze

  PILLOW_ASSESSMENT_TYPES = {
    fan_assessment: Assessments::FanAssessment
  }.freeze

  ALL_ASSESSMENT_TYPES =
    CASTLE_ASSESSMENT_TYPES.merge(PILLOW_ASSESSMENT_TYPES).freeze

  USER_EDITABLE_PARAMS = %i[
    has_slide
    height
    inspection_date
    inspection_location
    is_totally_enclosed
    length
    passed
    photo_1
    photo_2
    photo_3
    risk_assessment
    unique_report_number
    unit_id
    width
  ].freeze

  REQUIRED_TO_COMPLETE_FIELDS =
    USER_EDITABLE_PARAMS - %i[
      risk_assessment
      unique_report_number
    ]

  belongs_to :user
  belongs_to :unit, optional: true
  belongs_to :inspector_company, optional: true

  # File attachments
  has_one_attached :photo_1
  has_one_attached :photo_2
  has_one_attached :photo_3
  validate :photos_must_be_images

  ALL_ASSESSMENT_TYPES.each do |assessment_name, assessment_class|
    has_one assessment_name,
      class_name: assessment_class.name,
      dependent: :destroy
  end

  alias_method :tallest_user_height_assessment, :user_height_assessment

  # Accept nested attributes for all assessments
  accepts_nested_attributes_for(*ALL_ASSESSMENT_TYPES.keys)

  # Override assessment getters to auto-create if missing
  ALL_ASSESSMENT_TYPES.each do |assessment_name, assessment_class|
    # Auto-create version
    define_method(assessment_name) do
      super() || assessment_class.find_or_create_by!(inspection: self)
    end

    # Non-creating version for safe navigation
    define_method("#{assessment_name}?") do
      association(assessment_name).loaded? ? send(assessment_name) :
        assessment_class.find_by(inspection: self)
    end
  end

  validates :inspection_location, presence: true, if: :complete?
  validates :inspection_date, presence: true
  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :unique_report_number,
    uniqueness: {scope: :user_id, allow_blank: true}
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  # Callbacks
  before_validation :set_inspector_company_from_user, on: :create
  before_validation :set_inspection_type_from_unit, on: :create

  # Scopes
  scope :seed_data, -> { where(is_seed: true) }
  scope :non_seed_data, -> { where(is_seed: false) }
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }
  scope :complete, -> { where.not(complete_date: nil) }
  scope :draft, -> { where(complete_date: nil) }
  scope :search, ->(query) {
    if query.present?
      joins("LEFT JOIN units ON units.id = inspections.unit_id")
        .where(search_conditions, *search_values(query))
    else
      all
    end
  }
  scope :filter_by_result, ->(result) {
    case result
    when "passed" then where(passed: true)
    when "failed" then where(passed: false)
    end
  }
  scope :filter_by_unit, ->(unit_id) {
    where(unit_id: unit_id) if unit_id.present?
  }
  scope :filter_by_owner, ->(owner) {
    if owner.present?
      joins(:unit).where(units: {owner: owner})
    else
      all
    end
  }
  scope :filter_by_inspection_location, ->(location) {
    where(inspection_location: location) if location.present?
  }
  scope :filter_by_date_range, ->(start_date, end_date) {
    range = start_date..end_date
    where(inspection_date: range) if both_dates_present?(start_date, end_date)
  }
  scope :overdue, -> { where("inspection_date < ?", Time.zone.today - 1.year) }

  # Helper methods for scopes
  def self.search_conditions
    "inspections.inspection_location LIKE ? OR inspections.id LIKE ? OR " \
    "inspections.unique_report_number LIKE ? OR units.serial LIKE ? OR " \
    "units.manufacturer LIKE ? OR units.name LIKE ?"
  end

  def self.search_values(query) = Array.new(6) { "%#{query}%" }

  def self.both_dates_present?(start_date, end_date) =
    start_date.present? && end_date.present?

  # Calculated fields
  def reinspection_date
    return nil if inspection_date.blank?
    inspection_date + 1.year
  end

  def area
    return nil unless width && length
    width * length
  end

  def volume
    return nil unless width && length && height
    width * length * height
  end

  def complete?
    complete_date.present?
  end

  def assessment_types
    bouncing_pillow? ? PILLOW_ASSESSMENT_TYPES : CASTLE_ASSESSMENT_TYPES
  end

  def applicable_assessments
    if bouncing_pillow?
      pillow_applicable_assessments
    else
      castle_applicable_assessments
    end
  end

  private

  def castle_applicable_assessments
    CASTLE_ASSESSMENT_TYPES.select do |assessment_key, _|
      case assessment_key
      when :slide_assessment
        has_slide?
      when :enclosed_assessment
        is_totally_enclosed?
      else
        true
      end
    end
  end

  def pillow_applicable_assessments
    PILLOW_ASSESSMENT_TYPES
  end

  public

  # Iterate over only applicable assessments with a block
  def each_applicable_assessment
    applicable_assessments.each do |assessment_key, assessment_class|
      assessment = send(assessment_key)
      yield(assessment_key, assessment_class, assessment) if block_given?
    end
  end

  # Check if a specific assessment is applicable
  def assessment_applicable?(assessment_key)
    applicable_assessments.key?(assessment_key)
  end

  # Returns tabs in the order they appear in the UI
  def applicable_tabs
    tabs = ["inspection"]

    # Get applicable assessments for this inspection type
    applicable = applicable_assessments.keys.map { |k| k.to_s.chomp("_assessment") }

    # Add tabs in the correct UI order
    ordered_tabs = %w[user_height slide structure anchorage materials fan enclosed]
    ordered_tabs.each do |tab|
      tabs << tab if applicable.include?(tab)
    end

    # Add results tab at the end
    tabs << "results"

    tabs
  end

  # Advanced methods
  def can_be_completed?
    unit.present? &&
      all_assessments_complete? &&
      inspection_location.present? &&
      !passed.nil? &&
      inspection_date.present? &&
      width.present? &&
      length.present? &&
      height.present? &&
      !has_slide.nil? &&
      !is_totally_enclosed.nil?
  end

  def completion_status
    complete = complete?
    all_assessments_complete = all_assessments_complete?
    missing_assessments = get_missing_assessments
    can_be_completed = can_be_completed?

    {
      complete:,
      all_assessments_complete:,
      missing_assessments:,
      can_be_completed:
    }
  end

  def can_mark_complete? = can_be_completed?

  def completion_errors
    errors = []
    errors << "Unit is required" if unit.blank?
    errors += get_missing_assessments.map { |assessment| "#{assessment} Assessment incomplete" }
    errors
  end

  def get_missing_assessments
    missing = []

    # Check for missing unit first
    missing << "Unit" if unit.blank?

    # Check for missing assessments using the new helper
    each_applicable_assessment do |assessment_key, _, assessment|
      unless assessment&.complete?
        # Get the assessment type without "_assessment" suffix
        assessment_type = assessment_key.to_s.sub("_assessment", "")
        # Get the name from the form header
        missing << I18n.t("forms.#{assessment_type}.header")
      end
    end

    missing
  end

  def complete!(user)
    update!(complete_date: Time.current)
    log_audit_action("completed", user, "Inspection completed")
  end

  def un_complete!(user)
    update!(complete_date: nil)
    log_audit_action("marked_incomplete", user, "Inspection completed")
  end

  def validate_completeness
    assessment_validation_data.filter_map do |name, assessment, message|
      # Convert the symbol name (e.g., :slide) to assessment key (e.g., :slide_assessment)
      assessment_key = :"#{name}_assessment"
      next unless assessment_applicable?(assessment_key)

      message if assessment&.present? && !assessment.complete?
    end
  end

  def log_audit_action(action, user, details)
    Event.log(
      user: user,
      action: action,
      resource: self,
      details: details
    )
  rescue => e
    # Fallback to logging if Event creation fails
    Rails.logger.error("Failed to create event: #{e.message}")
    Rails.logger.info("Inspection #{id}: #{action} by #{user&.email} - #{details}")
  end

  def field_label(form, field)
    key = "forms.#{form}.fields.#{field}"
    # Try the field as-is first
    label = I18n.t(key, default: nil)
    # Try removing _pass and/or _comment suffixes
    if label.nil?
      base_field = field.to_s.gsub(/_pass$|_comment$/, "")
      label = I18n.t("forms.#{form}.fields.#{base_field}", default: nil)
    end
    # Try adding _pass suffix
    if label.nil? && !field.to_s.end_with?("_pass")
      label = I18n.t("#{key}_pass", default: nil)
    end
    # If still not found, raise for the original key
    label || I18n.t(key)
  end

  def inspection_tab_incomplete_fields
    # Fields required for the inspection tab specifically (excludes passed which is on results tab)
    fields = REQUIRED_TO_COMPLETE_FIELDS - [:passed]
    fields
      .select { |f| !f.end_with?("_comment") }
      .select { |f| send(f).nil? }
  end

  def incomplete_fields
    output = []

    # Process tabs in the same order as applicable_tabs
    applicable_tabs.each do |tab|
      case tab
      when "inspection"
        # Get incomplete fields for the inspection tab (excluding passed)
        inspection_tab_fields =
          inspection_tab_incomplete_fields
            .map { |f| {field: f, label: field_label(:inspection, f)} }

        if inspection_tab_fields.any?
          output << {
            tab: :inspection,
            name: I18n.t("forms.inspection.header"),
            fields: inspection_tab_fields
          }
        end

      when "results"
        # Get incomplete fields for the results tab
        results_fields = []
        results_fields << {field: :passed, label: field_label(:results, :passed)} if passed.nil?

        if results_fields.any?
          output << {
            tab: :results,
            name: I18n.t("forms.results.header"),
            fields: results_fields
          }
        end

      else
        # All other tabs are assessment tabs
        assessment_key = :"#{tab}_assessment"
        assessment = send(assessment_key) if respond_to?(assessment_key)

        assessment_fields =
          assessment&.incomplete_fields
            &.map { |f| {field: f, label: field_label(tab.to_sym, f)} } ||
          []

        if assessment_fields.any?
          output << {
            tab: tab.to_sym,
            name: I18n.t("forms.#{tab}.header"),
            fields: assessment_fields
          }
        end
      end
    end

    output
  end

  private

  def set_inspector_company_from_user
    self.inspector_company_id ||= user.inspection_company_id
  end

  def set_inspection_type_from_unit
    return unless unit
    return unless new_record?

    # Set inspection type to match unit type
    self.inspection_type = unit.unit_type
  end

  def all_assessments_complete?
    required_assessment_completions.all?
  end

  def required_assessment_completions
    applicable_assessments.map do |assessment_key, _|
      send(assessment_key)&.complete?
    end
  end

  def all_assessments
    applicable_assessments.map { |assessment_key, _| send(assessment_key) }
  end

  private

  def assessment_validation_data
    assessment_types = %i[
      anchorage
      enclosed
      fan
      materials
      slide
      structure
      user_height
    ]

    assessment_types.map do |type|
      assessment = send("#{type}_assessment")
      message = I18n.t("inspections.validation.#{type}_incomplete")
      [type, assessment, message]
    end
  end

  def photos_must_be_images
    [[:photo_1, photo_1], [:photo_2, photo_2], [:photo_3, photo_3]].each do |field_name, photo|
      next unless photo.attached?

      # Check if blob exists and has content_type
      if photo.blob && !photo.blob.content_type.to_s.start_with?("image/")
        errors.add(field_name, I18n.t("activerecord.errors.messages.not_an_image"))
        photo.purge
      end
    end
  end
end
