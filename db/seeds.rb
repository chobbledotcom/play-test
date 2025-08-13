# TestLog Seed Data
# British inflatable equipment inspection system
# Run with: rails db:seed

Rails.logger.debug "Starting seed data creation..."
Rails.logger.debug { "Environment: #{Rails.env}" }

# Load seed files in correct order
load Rails.root.join("db/seeds/cleanup.rb")
load Rails.root.join("db/seeds/pages.rb")
load Rails.root.join("db/seeds/inspector_companies.rb")
load Rails.root.join("db/seeds/users.rb")
load Rails.root.join("db/seeds/units.rb")
load Rails.root.join("db/seeds/inspections.rb")

Rails.logger.debug "\n=== Seed Summary ==="
Rails.logger.debug { "Pages: #{Page.pages.count} (+ #{Page.snippets.count} snippets)" }
Rails.logger.debug { "Inspector Companies: #{InspectorCompany.count}" }
Rails.logger.debug { "Users: #{User.count}" }
Rails.logger.debug { "Units: #{Unit.count}" }
Rails.logger.debug { "Inspections: #{Inspection.count}" }
total_assessments = Inspection::CASTLE_ASSESSMENT_TYPES.values.sum(&:count)
Rails.logger.debug { "Total Assessments: #{total_assessments}" }
Rails.logger.debug "\nSeed data creation complete!"
