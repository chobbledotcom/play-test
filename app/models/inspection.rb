# typed: true
# frozen_string_literal: true

# == Schema Information
#
# Table name: inspections
#
#  id                   :string(12)       not null, primary key
#  complete_date        :datetime
#  has_slide            :boolean
#  height               :decimal(8, 2)
#  height_comment       :string(1000)
#  indoor_only          :boolean
#  inspection_date      :datetime
#  inspection_type      :string           default("bouncy_castle"), not null
#  is_seed              :boolean          default(FALSE), not null
#  is_totally_enclosed  :boolean
#  length               :decimal(8, 2)
#  length_comment       :string(1000)
#  passed               :boolean
#  pdf_last_accessed_at :datetime
#  risk_assessment      :text
#  width                :decimal(8, 2)
#  width_comment        :string(1000)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  inspector_company_id :string
#  unit_id              :string
#  user_id              :string(12)       not null
#
# Indexes
#
#  index_inspections_on_inspection_type       (inspection_type)
#  index_inspections_on_inspector_company_id  (inspector_company_id)
#  index_inspections_on_is_seed               (is_seed)
#  index_inspections_on_unit_id               (unit_id)
#  index_inspections_on_user_id               (user_id)
#
# Foreign Keys
#
#  inspector_company_id  (inspector_company_id => inspector_companies.id)
#  unit_id               (unit_id => units.id)
#  user_id               (user_id => users.id)
#
class Inspection < ApplicationRecord
  extend T::Sig

  include CustomIdGenerator
  include FormConfigurable
  include InspectionCompletion
  include ValidationConfigurable

  PASS_FAIL_NA = {fail: 0, pass: 1, na: 2}.freeze

  enum :inspection_type, Unit::UNIT_TYPES

  # One registry of the assessments each unit type carries. Kept in the
  # original merge order so ALL_ASSESSMENT_TYPES below is unchanged.
  UNIT_TYPE_ASSESSMENT_TYPES = {
    bouncy_castle: {
      user_height_assessment: Assessments::UserHeightAssessment,
      slide_assessment: Assessments::SlideAssessment,
      structure_assessment: Assessments::StructureAssessment,
      anchorage_assessment: Assessments::AnchorageAssessment,
      materials_assessment: Assessments::MaterialsAssessment,
      enclosed_assessment: Assessments::EnclosedAssessment,
      fan_assessment: Assessments::FanAssessment
    },
    bouncing_pillow: {
      fan_assessment: Assessments::FanAssessment,
      bouncing_pillow_assessment: Assessments::BouncingPillowAssessment
    },
    pat_testable: {
      pat_assessment: Assessments::PatAssessment
    },
    inflatable_ball_pool: {
      structure_assessment: Assessments::StructureAssessment,
      materials_assessment: Assessments::MaterialsAssessment,
      fan_assessment: Assessments::FanAssessment,
      anchorage_assessment: Assessments::AnchorageAssessment,
      ball_pool_assessment: Assessments::BallPoolAssessment
    },
    inflatable_game: {
      structure_assessment: Assessments::StructureAssessment,
      materials_assessment: Assessments::MaterialsAssessment,
      fan_assessment: Assessments::FanAssessment,
      anchorage_assessment: Assessments::AnchorageAssessment,
      slide_assessment: Assessments::SlideAssessment,
      enclosed_assessment: Assessments::EnclosedAssessment,
      inflatable_game_assessment: Assessments::InflatableGameAssessment
    },
    catch_bed: {
      structure_assessment: Assessments::StructureAssessment,
      materials_assessment: Assessments::MaterialsAssessment,
      fan_assessment: Assessments::FanAssessment,
      anchorage_assessment: Assessments::AnchorageAssessment,
      catch_bed_assessment: Assessments::CatchBedAssessment
    },
    bungee_run: {
      structure_assessment: Assessments::StructureAssessment,
      materials_assessment: Assessments::MaterialsAssessment,
      fan_assessment: Assessments::FanAssessment,
      anchorage_assessment: Assessments::AnchorageAssessment,
      bungee_assessment: Assessments::BungeeAssessment
    },
    play_zone: {
      structure_assessment: Assessments::StructureAssessment,
      materials_assessment: Assessments::MaterialsAssessment,
      fan_assessment: Assessments::FanAssessment,
      anchorage_assessment: Assessments::AnchorageAssessment,
      enclosed_assessment: Assessments::EnclosedAssessment,
      user_height_assessment: Assessments::UserHeightAssessment,
      slide_assessment: Assessments::SlideAssessment,
      play_zone_assessment: Assessments::PlayZoneAssessment
    }
  }.freeze

  ALL_ASSESSMENT_TYPES =
    UNIT_TYPE_ASSESSMENT_TYPES.values.reduce(:merge).freeze

  USER_EDITABLE_PARAMS = (%i[
    height
    inspection_date
    inspection_location
    length
    operator
    passed
    photo_1
    photo_2
    photo_3
    risk_assessment
    unit_id
    width
  ] + InspectionChecklist::COMPONENT_FIELDS).freeze

  belongs_to :user
  belongs_to :unit, optional: true
  belongs_to :inspector_company, optional: true

  has_one_attached :photo_1
  has_one_attached :photo_2
  has_one_attached :photo_3
  has_one_attached :cached_pdf
  validate :photos_must_be_images

  before_validation :set_inspector_company_from_user, on: :create
  before_validation :initialise_current_checklist, on: :create
  before_validation :synchronise_changed_unit, on: :update
  validate :configuration_is_applicable, if: :current_checklist?

  after_update :invalidate_pdf_cache
  after_save :invalidate_unit_pdf_cache
  after_save :prune_inapplicable_answers, if: :checklist_configuration_changed?

  ALL_ASSESSMENT_TYPES.each do |assessment_name, assessment_class|
    has_one assessment_name,
      class_name: assessment_class.name,
      inverse_of: :inspection,
      dependent: :destroy
  end

  # Accept nested attributes for all assessments
  accepts_nested_attributes_for(*ALL_ASSESSMENT_TYPES.keys)

  # Reading an inspection must not create assessment records or upgrade
  # history.
  ALL_ASSESSMENT_TYPES.each_key do |assessment_name|
    define_method(assessment_name) do
      super() || public_send("build_#{assessment_name}")
    end

    define_method("#{assessment_name}?") do
      association(assessment_name).reader
    end
  end

  validates :inspection_date, presence: true

  # Scopes
  scope :seed_data, -> { where(is_seed: true) }
  scope :non_seed_data, -> { where(is_seed: false) }
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }
  scope :complete, -> { where.not(complete_date: nil) }
  scope :draft, -> { where(complete_date: nil) }
  scope :search, lambda { |query|
    if query.present?
      joins("LEFT JOIN units ON units.id = inspections.unit_id")
        .where(search_conditions, *search_values(query))
    else
      all
    end
  }
  scope :filter_by_result, lambda { |result|
    case result
    when "passed" then where(passed: true)
    when "failed" then where(passed: false)
    end
  }
  scope :filter_by_unit, lambda { |unit_id|
    where(unit_id: unit_id) if unit_id.present?
  }
  scope :filter_by_operator, lambda { |operator|
    where(operator: operator) if operator.present?
  }
  scope :filter_by_date_range, lambda { |start_date, end_date|
    range = start_date..end_date
    where(inspection_date: range) if both_dates_present?(start_date, end_date)
  }
  scope :overdue, -> { where("inspection_date < ?", Time.zone.today - 1.year) }

  # Helper methods for scopes
  sig { returns(String) }
  def self.search_conditions
    "inspections.id LIKE ? OR units.serial LIKE ? OR " \
    "units.manufacturer LIKE ? OR units.name LIKE ?"
  end

  sig { params(query: String).returns(T::Array[String]) }
  def self.search_values(query) = Array.new(4) { "%#{query}%" }

  sig { params(start_date: T.nilable(T.any(String, Date)), end_date: T.nilable(T.any(String, Date))).returns(T::Boolean) }
  def self.both_dates_present?(start_date, end_date) =
    start_date.present? && end_date.present?

  # Calculated fields
  sig { returns(T.nilable(Date)) }
  def reinspection_date
    return nil if inspection_date.blank?

    (inspection_date + 1.year).to_date
  end

  sig { returns(T.nilable(Numeric)) }
  def area
    return nil unless width && length

    width * length
  end

  sig { returns(T.nilable(Numeric)) }
  def volume
    return nil unless width && length && height

    width * length * height
  end

  sig { returns(T::Boolean) }
  def complete?
    complete_date.present?
  end

  sig { returns(T::Hash[Symbol, T.class_of(ApplicationRecord)]) }
  def assessment_types
    UNIT_TYPE_ASSESSMENT_TYPES.fetch(inspection_type.to_sym)
  end

  sig { returns(InspectionChecklist) }
  def checklist
    @checklist ||= InspectionChecklist.new(self)
  end

  sig { returns(T::Boolean) }
  def current_checklist?
    checklist_revision == InspectionChecklist::CURRENT_REVISION
  end

  sig { returns(T::Hash[Symbol, T.class_of(ApplicationRecord)]) }
  def applicable_assessments
    assessment_types.slice(*checklist.assessment_names)
  end

  sig { returns(Inspection) }
  def prepare_for_edit!
    legacy = !current_checklist?
    synchronise_unit_configuration if unit &&
      inspection_type != unit.unit_type
    self.checklist_revision = InspectionChecklist::CURRENT_REVISION
    initialise_snapshot_fields
    InspectionChecklist.normalise_type_change(self, inspection_type) if legacy
    self
  end

  # Iterate over only applicable assessments with a block
  sig { params(block: T.proc.params(assessment_key: Symbol, assessment_class: T.class_of(ApplicationRecord), assessment: ApplicationRecord).void).void }
  def each_applicable_assessment(&block)
    applicable_assessments.each do |assessment_key, assessment_class|
      assessment = send(assessment_key)
      yield(assessment_key, assessment_class, assessment) if block_given?
    end
  end

  # Check if a specific assessment is applicable
  sig { params(assessment_key: Symbol).returns(T::Boolean) }
  def assessment_applicable?(assessment_key)
    applicable_assessments.key?(assessment_key)
  end

  # Returns tabs in the order they appear in the UI
  sig { returns(T::Array[String]) }
  def applicable_tabs
    tabs = ["inspection"]

    # Get applicable assessments for this inspection type
    applicable = applicable_assessments.keys.map { |k| k.to_s.chomp("_assessment") }

    # Add tabs in the correct UI order
    ordered_tabs = %w[user_height slide structure anchorage materials bouncing_pillow fan enclosed pat ball_pool bungee catch_bed inflatable_game play_zone]
    ordered_tabs.each do |tab|
      tabs << tab if applicable.include?(tab)
    end

    # Add results tab at the end
    tabs << "results"

    tabs
  end

  sig { params(action: String, user: T.nilable(User), details: String).void }
  def log_audit_action(action, user, details)
    Event.log(
      user: user,
      action: action,
      resource: self,
      details: details
    )
  end

  sig {
    params(
      form: T.any(Symbol, String),
      field: T.any(Symbol, String)
    ).returns(String)
  }
  def field_label(form, field)
    if !current_checklist? && form.to_s == "bungee" &&
        ChobbleForms::FieldUtils.strip_field_suffix(field) == :pull_strength
      return I18n.t("forms.bungee.legacy_fields.pull_strength")
    end

    key = "forms.#{form}.fields.#{field}"
    label = I18n.t(key, default: nil)
    if label.nil?
      base = ChobbleForms::FieldUtils.strip_field_suffix(field)
      label = I18n.t(
        "forms.#{form}.fields.#{base}", default: nil
      )
    end
    if label.nil? && !field.to_s.end_with?("_pass")
      label = I18n.t("#{key}_pass", default: nil)
    end
    label || I18n.t(key)
  end

  private

  sig { void }
  def set_inspector_company_from_user
    self.inspector_company_id ||= user.inspection_company_id
  end

  sig { void }
  def initialise_current_checklist
    self.checklist_revision = InspectionChecklist::CURRENT_REVISION
    self.inspection_type = unit.unit_type if unit
    initialise_snapshot_fields
  end

  sig { void }
  def initialise_snapshot_fields
    defaults = if unit
      unit.configuration_snapshot
    else
      InspectionChecklist.configuration_defaults(inspection_type)
    end
    defaults.each { |field, value| self[field] = value if self[field].nil? }
  end

  sig { void }
  def synchronise_changed_unit
    return unless will_save_change_to_unit_id?

    self.checklist_revision = InspectionChecklist::CURRENT_REVISION
    synchronise_unit_configuration if unit
  end

  sig { void }
  def synchronise_unit_configuration
    self.inspection_type = unit.unit_type
    assign_attributes(unit.configuration_snapshot)
  end

  sig { void }
  def configuration_is_applicable
    InspectionChecklist.validate_configuration(self, inspection_type)
  end

  sig { returns(T::Boolean) }
  def checklist_configuration_changed?
    return false if previously_new_record? || !current_checklist?

    fields = InspectionChecklist::COMPONENT_FIELDS +
      %i[checklist_revision inspection_type unit_id]
    fields.any? { |field| saved_change_to_attribute?(field) }
  end

  sig { void }
  def prune_inapplicable_answers
    configuration = InspectionChecklist.component_fields(inspection_type)
    return if configuration.any? { |field| self[field].nil? }

    applicable = applicable_assessments.keys
    ALL_ASSESSMENT_TYPES.each_key do |key|
      assessment = public_send("#{key}?")
      next unless assessment

      if applicable.include?(key)
        prune_hidden_fields(assessment)
      elsif assessment.persisted?
        assessment.destroy!
      else
        association(key).reset
      end
    end
  end

  sig { params(assessment: ApplicationRecord).void }
  def prune_hidden_fields(assessment)
    schema = assessment.class.assessment_schema
    hidden = schema.attribute_names - assessment.form_schema.attribute_names
    hidden &= assessment.class.column_name_syms
    values = hidden.to_h { |field| [field, nil] }
    assessment.assign_attributes(values)
    assessment.save! if assessment.changed?
  end

  sig { returns(T::Boolean) }
  def all_assessments_complete?
    required_assessment_completions.all?
  end

  sig { returns(T::Array[T::Boolean]) }
  def required_assessment_completions
    applicable_assessments.map do |assessment_key, _|
      send(assessment_key)&.complete?
    end
  end

  sig { returns(T::Array[ApplicationRecord]) }
  def all_assessments
    applicable_assessments.map { |assessment_key, _| send(assessment_key) }
  end

  sig { void }
  def photos_must_be_images
    photos = {photo_1:, photo_2:, photo_3:}
    photos.each do |field_name, photo|
      next unless photo.attached?
      next unless photo.blob

      content_type = photo.blob.content_type.to_s
      unless content_type.start_with?("image/")
        msg = I18n.t(
          "activerecord.errors.messages.not_an_image"
        )
        errors.add(field_name, msg)
        photo.purge
      end
    end
  end

  sig { void }
  def invalidate_pdf_cache
    # Skip cache invalidation if only pdf_last_accessed_at or updated_at changed
    changed_attrs = saved_changes.keys
    ignorable_attrs = ["pdf_last_accessed_at", "updated_at"]

    return if (changed_attrs - ignorable_attrs).empty?

    PdfCacheService.invalidate_inspection_cache(self)
  end

  sig { void }
  def invalidate_unit_pdf_cache
    changed_attrs = saved_changes.keys
    ignorable_attrs = ["pdf_last_accessed_at", "updated_at"]

    return if (changed_attrs - ignorable_attrs).empty?

    PdfCacheService.invalidate_unit_cache(unit) if unit
  end
end
