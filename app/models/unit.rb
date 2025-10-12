# typed: true
# frozen_string_literal: true

# == Schema Information
#
# Table name: units
#
#  id               :string(8)        not null, primary key
#  description      :string
#  is_seed          :boolean          default(FALSE), not null
#  manufacture_date :date
#  manufacturer     :string
#  name             :string
#  operator         :string
#  serial           :string
#  unit_type        :string           default("bouncy_castle"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :string(8)        not null
#
# Indexes
#
#  index_units_on_is_seed                  (is_seed)
#  index_units_on_manufacturer_and_serial  (manufacturer,serial) UNIQUE
#  index_units_on_serial_and_user_id       (serial,user_id) UNIQUE
#  index_units_on_unit_type                (unit_type)
#  index_units_on_user_id                  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Unit < ApplicationRecord
  extend T::Sig
  self.table_name = "units"
  include CustomIdGenerator

  enum :unit_type, {
    bouncy_castle: "BOUNCY_CASTLE",
    bouncing_pillow: "BOUNCING_PILLOW"
  }

  belongs_to :user
  has_many :inspections
  has_many :complete_inspections, -> { where.not(complete_date: nil) }, class_name: "Inspection"
  has_many :draft_inspections, -> { where(complete_date: nil) }, class_name: "Inspection"

  # File attachments
  has_one_attached :photo
  has_one_attached :cached_pdf
  validate :photo_must_be_image

  # Callbacks
  before_validation :normalize_id, on: :create, if: -> { unit_badges_enabled? }
  before_create :generate_custom_id, unless: -> { unit_badges_enabled? }
  before_create :validate_badge_id, if: -> { unit_badges_enabled? }
  after_update :invalidate_pdf_cache
  before_destroy :check_complete_inspections
  before_destroy :destroy_draft_inspections

  # All fields are required for Units
  validates :name, :serial, :description, :manufacturer, :operator, presence: true
  validates :serial, uniqueness: {scope: [:user_id]}
  validates :id, presence: true, if: -> { unit_badges_enabled? && new_record? }

  # Scopes - enhanced from original Equipment and new Unit functionality
  scope :seed_data, -> { where(is_seed: true) }
  scope :non_seed_data, -> { where(is_seed: false) }
  scope :search, ->(query) {
    if query.present?
      search_term = "%#{query}%"
      where(<<~SQL, *([search_term] * 5))
        serial LIKE ?
        OR name LIKE ?
        OR description LIKE ?
        OR manufacturer LIKE ?
        OR operator LIKE ?
      SQL
    else
      all
    end
  }
  scope :by_manufacturer, ->(manufacturer) { where(manufacturer: manufacturer) if manufacturer.present? }
  scope :by_operator, ->(operator) { where(operator: operator) if operator.present? }
  scope :with_recent_inspections, -> {
    cutoff_date = EN14960::Constants::REINSPECTION_INTERVAL_DAYS.days.ago
    joins(:inspections)
      .where(inspections: {inspection_date: cutoff_date..})
      .distinct
  }

  scope :inspection_due, -> {
    joins(:inspections)
      .merge(Inspection.complete)
      .group("units.id")
      .having("MAX(inspections.complete_date) + INTERVAL #{EN14960::Constants::REINSPECTION_INTERVAL_DAYS} DAY <= CURRENT_DATE")
  }

  # Instance methods

  sig { returns(T.nilable(Inspection)) }
  def last_inspection
    @last_inspection ||= inspections.merge(Inspection.complete).order(complete_date: :desc).first
  end

  sig { returns(String) }
  def last_inspection_status
    last_inspection&.passed? ? "Passed" : "Failed"
  end

  sig { returns(ActiveRecord::Relation) }
  def inspection_history
    inspections.includes(:user).order(inspection_date: :desc)
  end

  sig { returns(T.nilable(Date)) }
  def next_inspection_due
    return nil unless last_inspection
    (last_inspection.inspection_date + EN14960::Constants::REINSPECTION_INTERVAL_DAYS.days).to_date
  end

  sig { returns(T::Boolean) }
  def inspection_overdue?
    return false unless next_inspection_due
    next_inspection_due < Date.current
  end

  sig { returns(String) }
  def compliance_status
    return "Never Inspected" unless last_inspection

    if inspection_overdue?
      "Overdue"
    elsif last_inspection.passed?
      "Compliant"
    else
      "Non-Compliant"
    end
  end

  sig {
    returns(T::Hash[Symbol, T.any(Integer, T.nilable(Date), T.nilable(String))])
  }
  def inspection_summary
    {
      total_inspections: inspections.count,
      passed_inspections: inspections.passed.count,
      failed_inspections: inspections.failed.count,
      last_inspection_date: last_inspection&.inspection_date,
      next_due_date: next_inspection_due,
      compliance_status: compliance_status
    }
  end

  sig { returns(T::Boolean) }
  def deletable?
    !complete_inspections.exists?
  end

  private

  sig { void }
  def check_complete_inspections
    if complete_inspections.exists?
      errors.add(:base, :has_complete_inspections)
      throw(:abort)
    end
  end

  sig { void }
  def destroy_draft_inspections
    draft_inspections.destroy_all
  end

  public

  sig { returns(ActiveRecord::Relation) }
  def self.overdue
    # Find units where their most recent inspection is older than the interval
    # Using Date.current instead of Date.today for Rails timezone consistency
    cutoff_date = Date.current - EN14960::Constants::REINSPECTION_INTERVAL_DAYS.days
    joins(:inspections)
      .group("units.id")
      .having("MAX(inspections.inspection_date) <= ?", cutoff_date)
  end

  private

  sig { void }
  def check_for_complete_inspections
    if complete_inspections.exists?
      errors.add(:base, :has_complete_inspections)
      throw(:abort)
    end
  end

  sig { void }
  def photo_must_be_image
    return unless photo.attached?

    unless photo.blob.content_type.start_with?("image/")
      errors.add(:photo, "must be an image file")
      photo.purge
    end
  end

  sig { void }
  def invalidate_pdf_cache
    # Skip cache invalidation if only updated_at changed
    changed_attrs = saved_changes.keys
    ignorable_attrs = ["updated_at"]

    return if (changed_attrs - ignorable_attrs).empty?

    PdfCacheService.invalidate_unit_cache(self)
  end

  sig { returns(T::Boolean) }
  def unit_badges_enabled?
    ENV["UNIT_BADGES"] == "true"
  end

  sig { void }
  def normalize_id
    return unless id.present?

    # Strip spaces, uppercase, and trim to 8 characters
    normalized = id.gsub(/\s+/, "").upcase[0, 8]
    self.id = normalized
  end

  sig { void }
  def validate_badge_id
    return unless id.present?

    # Check if badge exists
    unless Badge.exists?(id: id)
      error_msg = I18n.t("units.validations.invalid_badge_id")
      errors.add(:id, error_msg)
      throw(:abort)
    end
  end
end
