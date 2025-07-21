if Rails.env.development?
  Rails.logger.debug "Cleaning up development data..."

  # Destroy assessments
  Inspection::ALL_ASSESSMENT_TYPES.each do |_, assessment_class|
    assessment_class.destroy_all
  end

  # Destroy core records
  Inspection.destroy_all
  Unit.destroy_all
  User.destroy_all
  InspectorCompany.destroy_all

  # Clean active storage
  ActiveStorage::Attachment.all.find_each(&:purge)
  ActiveStorage::Blob.all.find_each(&:purge)

  Rails.logger.debug "Development data cleanup complete."
end
