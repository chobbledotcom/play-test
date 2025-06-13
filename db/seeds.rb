# TestLog Seed Data
# British inflatable equipment inspection system
# Run with: rails db:seed
#
# SECURITY NOTE: All seed users are created with random 32-character passwords
# to prevent unauthorized access if seed data is accidentally left in production.
# These passwords are not logged or displayed anywhere.

puts "Starting seed data creation..."
puts "Environment: #{Rails.env}"

# Load shared test data helpers
require_relative "../lib/test_data_helpers"

# Load seed files in correct order
load Rails.root.join("db", "seeds", "cleanup.rb")
load Rails.root.join("db", "seeds", "inspector_companies.rb")
load Rails.root.join("db", "seeds", "users.rb")
load Rails.root.join("db", "seeds", "units.rb")
load Rails.root.join("db", "seeds", "inspections.rb")

puts "\n=== Seed Summary ==="
puts "Inspector Companies: #{InspectorCompany.count}"
puts "Users: #{User.count}"
puts "Units: #{Unit.count}"
puts "Inspections: #{Inspection.count}"
total_assessments = Inspection::ASSESSMENT_TYPES.values.sum(&:count)
puts "Total Assessments: #{total_assessments}"
puts "\nSeed data creation complete!"
