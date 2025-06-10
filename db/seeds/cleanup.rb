if Rails.env.development?
  puts "Cleaning up development data..."

  destroy_assessments
  destroy_core_records
  clean_active_storage

  puts "Development data cleanup complete."
end

private

def destroy_assessments
  UserHeightAssessment.destroy_all
  StructureAssessment.destroy_all
  SlideAssessment.destroy_all
  MaterialsAssessment.destroy_all
  FanAssessment.destroy_all
  EnclosedAssessment.destroy_all
  AnchorageAssessment.destroy_all
end

def destroy_core_records
  Inspection.destroy_all
  Unit.destroy_all
  User.destroy_all
  InspectorCompany.destroy_all
end

def clean_active_storage
  ActiveStorage::Attachment.all.each(&:purge)
  ActiveStorage::Blob.all.each(&:purge)
end