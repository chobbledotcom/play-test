#!/usr/bin/env ruby
# typed: false
# frozen_string_literal: true

require_relative "config/environment"

puts "Testing Litestream replication..."
puts "=" * 60

# Check WAL mode
ActiveRecord::Base.connection_pool.with_connection do |conn|
  mode = conn.execute("PRAGMA journal_mode").first["journal_mode"]
  puts "Current journal mode: #{mode}"

  if mode != "wal"
    puts "ERROR: Database is not in WAL mode!"
    exit 1
  end
end

# Create a test table and record
ActiveRecord::Base.connection.execute(<<~SQL)
  CREATE TABLE IF NOT EXISTS litestream_test (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message TEXT,
    created_at TEXT
  )
SQL

timestamp = Time.now.to_i

ActiveRecord::Base.connection.execute(<<~SQL)
  INSERT INTO litestream_test (message, created_at)
  VALUES ('test_#{timestamp}', datetime('now'))
SQL

puts "✓ Created test record with timestamp: #{timestamp}"
puts
puts "Waiting 15 seconds for Litestream to sync to S3..."
puts "(Litestream syncs every 10 seconds)"
puts

sleep 15

puts "✓ Wait complete!"
puts
puts "Check your S3 bucket at: play-test-dev"
puts "You should see:"
puts "  - development.sqlite3/ folder"
puts "  - WAL segments and snapshots inside"
puts
puts "=" * 60
