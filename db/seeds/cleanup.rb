if Rails.env.development?
  puts "Cleaning up development data..."

  # Destroy assessments
  UserHeightAssessment.destroy_all
  StructureAssessment.destroy_all
  SlideAssessment.destroy_all
  MaterialsAssessment.destroy_all
  FanAssessment.destroy_all
  EnclosedAssessment.destroy_all
  AnchorageAssessment.destroy_all

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