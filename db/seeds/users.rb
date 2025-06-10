# Users seed data

# Generate random secure passwords for seed users
def generate_secure_password
  SecureRandom.alphanumeric(32)
end

puts "Creating users..."

# Test user with access to all data
test_user = User.create!(
  email: "test@play-test.co.uk",
  password: generate_secure_password,
  rpii_inspector_number: "RPII-001",
  inspection_company: $stefan_testing,
  time_display: "time",
  active_until: Date.current + 1.year
)

# Stefan's Testing users
lead_inspector = User.create!(
  email: "lead@play-test.co.uk",
  password: generate_secure_password,
  rpii_inspector_number: "RPII-002",
  inspection_company: $stefan_testing,
  time_display: "time",
  active_until: Date.current + 1.year
)

User.create!(
  email: "junior@play-test.co.uk",
  password: generate_secure_password,
  rpii_inspector_number: "RPII-003",
  inspection_company: $stefan_testing,
  time_display: "date",
  active_until: Date.current + 1.year
)

User.create!(
  email: "senior@play-test.co.uk",
  password: generate_secure_password,
  rpii_inspector_number: "RPII-004",
  inspection_company: $stefan_testing,
  time_display: "time",
  active_until: Date.current + 1.year
)

# Steph Test user
steph_test_inspector = User.create!(
  email: "inspector@play-test.co.uk",
  password: generate_secure_password,
  rpii_inspector_number: "RPII-005",
  inspection_company: $steph_test,
  time_display: "date",
  active_until: Date.current + 1.year
)

# Retired company user
User.create!(
  email: "old@play-test.co.uk",
  password: generate_secure_password,
  rpii_inspector_number: "RPII-006",
  inspection_company: $steve_inflatable,
  time_display: "date",
  active_until: Date.current - 1.day
)

# Make key users available globally for other seed files
$test_user = test_user
$lead_inspector = lead_inspector
$steph_test_inspector = steph_test_inspector

puts "Created #{User.count} users."