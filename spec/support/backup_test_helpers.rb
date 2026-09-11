# typed: false
# frozen_string_literal: true

require "stringio"
require "sqlite3"
require "active_storage/service/disk_service"

# In-memory S3 for backup tests. Implements the small slice of the
# Aws::S3::Resource API that the backup services rely on.
class FakeS3Resource
  attr_reader :store

  def initialize(bucket = "test-bucket")
    @bucket = bucket
    @store = {}
  end

  def bucket(name)
    raise "Unexpected bucket #{name}" unless name == @bucket

    self
  end

  def object(key)
    FakeS3Object.new(self, key)
  end

  def objects(prefix:)
    @store.select { |key, _| key.start_with?(prefix) }
      .map { |key, payload| FakeS3ObjectSummary.new(key, payload) }
  end
end

class FakeS3Object
  attr_reader :key

  def initialize(resource, key)
    @resource = resource
    @key = key
  end

  def put(body:)
    content = body.respond_to?(:read) ? body.read : body
    @resource.store[@key] = {content: content, last_modified: @last_modified || Time.now.utc}
    self
  end

  def with_last_modified(time)
    @last_modified = time
    self
  end

  def get
    raise Aws::S3::Errors::NoSuchKey.new(nil, "No such key: #{@key}") unless exists?

    body = StringIO.new(@resource.store.fetch(@key)[:content])
    FakeS3GetOutput.new(body)
  end

  def exists?
    @resource.store.key?(@key)
  end

  def delete
    @resource.store.delete(@key)
    self
  end
end

class FakeS3GetOutput
  attr_reader :body

  def initialize(body)
    @body = body
  end
end

class FakeS3ObjectSummary
  attr_reader :key, :last_modified

  def initialize(key, payload)
    @key = key
    @last_modified = payload[:last_modified]
  end
end

# Creates a real SQLite database file at +path+ with a widgets table (and an
# active_storage_blobs table when +blobs+ is given). Used by the end-to-end
# backup tests so they exercise real database files.
def create_sqlite_database(path, rows: [], blobs: [])
  FileUtils.mkdir_p(File.dirname(path))
  db = SQLite3::Database.new(path.to_s)
  db.execute("CREATE TABLE widgets (id INTEGER PRIMARY KEY, name TEXT NOT NULL)")
  rows.each { |name| db.execute("INSERT INTO widgets (name) VALUES (?)", name) }

  unless blobs.empty?
    db.execute("CREATE TABLE active_storage_blobs (id INTEGER PRIMARY KEY, key TEXT NOT NULL, filename TEXT, service_name TEXT)")
    blobs.each do |blob|
      db.execute(
        "INSERT INTO active_storage_blobs (key, filename, service_name) VALUES (?, ?, ?)",
        [blob[:key], blob[:filename], blob[:service_name]]
      )
    end
  end
  db
ensure
  db&.close
end

def widget_names(db_path)
  db = SQLite3::Database.new(db_path.to_s)
  db.execute("SELECT name FROM widgets ORDER BY id").flatten
ensure
  db&.close
end

def blob_service_names(db_path)
  db = SQLite3::Database.new(db_path.to_s)
  db.execute("SELECT service_name FROM active_storage_blobs ORDER BY id").flatten
ensure
  db&.close
end
