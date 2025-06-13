# Support for running tests with in-memory SQLite database
# Based on https://railsatscale.com/2023-08-25-how-we-used-a-sqlite-memory-db-for-rails-benchmarking/

if ENV['IN_MEMORY_DB'] == 'true' && Rails.env.test?
  RSpec.configure do |config|
    config.before(:suite) do
      # Establish in-memory database connection
      ActiveRecord::Base.establish_connection(
        adapter: 'sqlite3',
        database: ':memory:',
        pool: 10,
        timeout: 10000
      )
      
      # Load schema directly into memory database
      ActiveRecord::Schema.verbose = false
      load Rails.root.join('db/schema.rb')
      
      puts "✅ Using in-memory SQLite database for tests"
    end
    
    # Optional: If you need to copy data from an existing test database
    # config.before(:suite) do
    #   mem_db = ActiveRecord::Base.connection.raw_connection
    #   file_db = SQLite3::Database.new(Rails.root.join('storage/test.sqlite3').to_s)
    #   backup = SQLite3::Backup.new(mem_db, 'main', file_db, 'main')
    #   backup.step(-1)
    #   backup.finish
    # end
  end
end