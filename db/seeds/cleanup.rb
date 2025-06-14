if Rails.env.development?
  puts "Cleaning up development data..."

  # Destroy assessments
  Inspection::ASSESSMENT_TYPES.each do |_, assessment_class|
    assessment_class.destroy_all
  end

  # Destroy core records
  Inspection.destroy_all
  Unit.destroy_all
  User.destroy_all
  InspectorCompany.destroy_all

  # Clean active storage
  ActiveStorage::Attachment.all.each(&:purge)
  ActiveStorage::Blob.all.each(&:purge)

  puts "Development data cleanup complete."
end
