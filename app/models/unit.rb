# RPII Utility - Unit model for bouncy castle inspection system
class Unit < ApplicationRecord
  self.table_name = "units"
  include CustomIdGenerator
  include HasDimensions

  belongs_to :user
  has_many :inspections
  has_many :complete_inspections, -> { where.not(complete_date: nil) }, class_name: "Inspection"
  has_many :draft_inspections, -> { where(complete_date: nil) }, class_name: "Inspection"

  # File attachments
  has_one_attached :photo

  # Callbacks
  before_destroy :check_for_complete_inspections
  after_commit :process_photo_upload, on: [:create, :update]

  # All fields are required for Units
  validates :name, :serial, :description, :manufacturer, :owner, presence: true
  validates :serial, uniqueness: {scope: [:user_id]}

  # Override HasDimensions validations for required basic dimensions
  dimension_validation_options = {greater_than: 0, less_than: 200}
  validates :width, :length, :height,
    presence: true, numericality: dimension_validation_options

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
  scope :with_slide, -> { where(has_slide: true) }
  scope :without_slide, -> { where(has_slide: false) }
  scope :by_manufacturer, ->(manufacturer) { where(manufacturer: manufacturer) if manufacturer.present? }
  scope :by_owner, ->(owner) { where(owner: owner) if owner.present? }
  scope :with_recent_inspections, -> {
    cutoff_date = SafetyStandard::REINSPECTION_INTERVAL_DAYS.days.ago
    joins(:inspections)
      .where(inspections: {inspection_date: cutoff_date..})
      .distinct
  }

  # Callbacks
  before_create :generate_custom_id
  after_update :update_inspection_unit_data, if: :saved_changes_to_dimensions?

  # Additional methods beyond HasDimensions concern

  def last_inspection
    inspections.order(inspection_date: :desc).first
  end

  def last_inspection_status
    last_inspection&.passed? ? "Passed" : "Failed"
  end

  def inspection_history
    inspections.includes(:user).order(inspection_date: :desc)
  end

  def requires_enclosed_assessment?
    is_totally_enclosed?
  end

  def next_inspection_due
    return nil unless last_inspection
    # Standard inspection interval using safety standard constant
    reinspection_interval = SafetyStandard::REINSPECTION_INTERVAL_DAYS.days
    last_inspection.inspection_date + reinspection_interval
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

  def destroy
    # Check if unit can be deleted before attempting destroy
    if complete_inspections.exists?
      errors.add(:base, :has_complete_inspections)
      return false
    end

    # Manually destroy draft inspections first
    draft_inspections.destroy_all

    # Then destroy the unit
    super
  end

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

  def saved_changes_to_dimensions?
    # Use dimension_changed? from HasDimensions for saved changes
    dimension_attributes.keys.any? { saved_change_to_attribute?(it) }
  end

  def update_inspection_unit_data
    # Update any draft inspections with new unit dimensions
    audit_message = "Unit dimensions updated"
    inspections.each do |inspection|
      inspection.log_audit_action("unit_updated", user, audit_message)
    end
  end

  def process_photo_upload
    return unless photo.attached?
    return if @photo_processed # Prevent infinite loops

    # Check if photo needs processing (not already processed)
    begin
      image = PdfGeneratorService::ImageProcessor.create_image(photo)
      needs_processing = image.width > ImageProcessorService::FULL_SIZE ||
        image.height > ImageProcessorService::FULL_SIZE ||
        PdfGeneratorService::ImageOrientationProcessor.needs_orientation_correction?(image) ||
        photo.content_type != "image/jpeg"

      return unless needs_processing

      # Get the uploaded file data
      uploaded_file_data = photo.download

      # Process the photo
      processed_io = PhotoProcessingService.process_upload_data(uploaded_file_data, photo.filename.to_s)

      if processed_io
        @photo_processed = true
        # Replace the attachment with processed version
        photo.detach
        photo.attach(
          io: processed_io,
          filename: processed_io.original_filename,
          content_type: processed_io.content_type
        )
        @photo_processed = false
      end
    rescue => e
      Rails.logger.error "Photo processing failed: #{e.message}"
      # For invalid images, detach them
      photo.detach
    end
  end
end
