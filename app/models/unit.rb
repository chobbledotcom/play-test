class Unit < ApplicationRecord
  self.table_name = "units"
  include CustomIdGenerator

  belongs_to :user
  has_many :inspections
  has_many :complete_inspections, -> { where.not(complete_date: nil) }, class_name: "Inspection"
  has_many :draft_inspections, -> { where(complete_date: nil) }, class_name: "Inspection"

  # File attachments
  has_one_attached :photo
  validate :photo_must_be_image

  # Callbacks
  before_create :generate_custom_id
  before_destroy :check_complete_inspections
  before_destroy :destroy_draft_inspections

  # All fields are required for Units
  validates :name, :serial, :description, :manufacturer, :owner, presence: true
  validates :serial, uniqueness: {scope: [:user_id]}

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
        OR owner LIKE ?
      SQL
    else
      all
    end
  }
  scope :by_manufacturer, ->(manufacturer) { where(manufacturer: manufacturer) if manufacturer.present? }
  scope :by_owner, ->(owner) { where(owner: owner) if owner.present? }
  scope :with_recent_inspections, -> {
    cutoff_date = SafetyStandard::REINSPECTION_INTERVAL_DAYS.days.ago
    joins(:inspections)
      .where(inspections: {inspection_date: cutoff_date..})
      .distinct
  }

  scope :inspection_due, -> {
    joins(:inspections)
      .merge(Inspection.completed)
      .group("units.id")
      .having("MAX(inspections.complete_date) + INTERVAL #{SafetyStandard::REINSPECTION_INTERVAL_DAYS} DAY <= CURRENT_DATE")
  }

  # Instance methods

  def last_inspection
    @last_inspection ||= inspections.merge(Inspection.complete).order(complete_date: :desc).first
  end

  def last_inspection_status
    last_inspection&.passed? ? "Passed" : "Failed"
  end

  def inspection_history
    inspections.includes(:user).order(inspection_date: :desc)
  end

  def next_inspection_due
    return nil unless last_inspection
    last_inspection.inspection_date + SafetyStandard::REINSPECTION_INTERVAL_DAYS.days
  end

  def inspection_overdue?
    return false unless next_inspection_due
    next_inspection_due < Date.current
  end

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

  def deletable?
    !complete_inspections.exists?
  end

  private

  def check_complete_inspections
    if complete_inspections.exists?
      errors.add(:base, :has_complete_inspections)
      throw(:abort)
    end
  end

  def destroy_draft_inspections
    draft_inspections.destroy_all
  end

  public

  def self.overdue
    # Find units where their most recent inspection is older than the interval
    # Using Date.current instead of Date.today for Rails timezone consistency
    cutoff_date = Date.current - SafetyStandard::REINSPECTION_INTERVAL_DAYS.days
    joins(:inspections)
      .group("units.id")
      .having("MAX(inspections.inspection_date) <= ?", cutoff_date)
  end

  private

  def check_for_complete_inspections
    if complete_inspections.exists?
      errors.add(:base, :has_complete_inspections)
      throw(:abort)
    end
  end

  def photo_must_be_image
    return unless photo.attached?

    unless photo.blob.content_type.start_with?("image/")
      errors.add(:photo, "must be an image file")
      photo.purge
    end
  end
end
