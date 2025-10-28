# typed: false
# frozen_string_literal: true

namespace :s3 do
  define_method(:test_file_key) do
    "test-uploads/rails-s3-test-file.txt"
  end

  # Helper methods
  define_method(:ensure_s3_enabled) do
    return if ENV["USE_S3_STORAGE"] == "true"

    puts "❌ S3 storage is not enabled. Set USE_S3_STORAGE=true in your .env file"
    exit 1
  end

  define_method(:validate_s3_config) do
    required_vars = %w[S3_ENDPOINT S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_BUCKET]
    missing_vars = required_vars.select { |var| ENV[var].blank? }

    if missing_vars.any?
      error_msg = "Missing required S3 environment variables: #{missing_vars.join(", ")}"
      puts "❌ #{error_msg}"

      Sentry.capture_message(error_msg, level: "error", extra: {
        missing_vars: missing_vars,
        task: "s3:backup",
        environment: Rails.env
      })

      exit 1
    end
  end

  define_method(:get_s3_service) do
    service = ActiveStorage::Blob.service

    unless service.is_a?(ActiveStorage::Service::S3Service)
      puts "❌ Active Storage is not configured to use S3. Current service: #{service.class.name}"
      exit 1
    end

    service
  end

  define_method(:handle_s3_errors) do |&block|
    block.call
  rescue Aws::S3::Errors::ServiceError => e
    puts "\n❌ S3 Error: #{e.message}"
    Sentry.capture_exception(e)
    exit 1
  rescue => e
    puts "\n❌ Error: #{e.class.name} - #{e.message}"
    Sentry.capture_exception(e)
    exit 1
  end

  desc "Upload a test file to S3 (visible in web UI)"
  task upload_test: :environment do
    ensure_s3_enabled

    handle_s3_errors do
      service = get_s3_service

      test_content = <<~CONTENT
        Rails S3 Test File
        ==================

        This file was uploaded by the Rails S3 test rake task.

        Uploaded at: #{Time.current}
        Rails Environment: #{Rails.env}
        S3 Endpoint: #{ENV["S3_ENDPOINT"]}
        S3 Bucket: #{ENV["S3_BUCKET"]}

        You can delete this file by running: rake s3:delete_test
      CONTENT

      print "Uploading test file to S3 at '#{test_file_key}'... "
      service.upload(test_file_key, StringIO.new(test_content))
      puts "✅"

      puts "\n📁 File uploaded successfully!"
      puts "   Location: #{test_file_key}"
      puts "   Check your Hetzner web UI to see the file."
      puts "   To delete it, run: rake s3:delete_test"
    end
  end

  desc "Delete the test file from S3"
  task delete_test: :environment do
    ensure_s3_enabled

    handle_s3_errors do
      service = get_s3_service

      # Check if file exists before trying to delete
      print "Checking if test file exists... "
      begin
        service.download(test_file_key)
        puts "✅"
      rescue Aws::S3::Errors::NoSuchKey
        puts "❌"
        puts "\n⚠️  Test file not found at '#{test_file_key}'"
        puts "   Run 'rake s3:upload_test' first to create it."
        exit 1
      end

      print "Deleting test file from S3... "
      service.delete(test_file_key)
      puts "✅"

      puts "\n🗑️  File deleted successfully!"
      puts "   The file '#{test_file_key}' has been removed from S3."
    end
  end

  desc "Test S3 connectivity and configuration"
  task test: :environment do
    ensure_s3_enabled

    puts "Testing S3 connectivity..."
    puts "=" * 50
    puts "Endpoint: #{ENV["S3_ENDPOINT"]}"
    puts "Bucket: #{ENV["S3_BUCKET"]}"
    puts "Region: #{ENV["S3_REGION"].presence || "(empty)"}"
    puts "=" * 50

    handle_s3_errors do
      service = get_s3_service

      # Test 1: List objects (to verify connectivity and permissions)
      print "Testing bucket access... "
      service.send(:bucket).objects.limit(1).to_a
      puts "✅"

      # Test 2: Upload a test file
      print "Testing file upload... "
      test_key = "test/connection_test_#{Time.current.to_i}.txt"
      test_content = "S3 connection test at #{Time.current}"
      service.upload(test_key, StringIO.new(test_content))
      puts "✅"

      # Test 3: Download the test file
      print "Testing file download... "
      downloaded_content = service.download(test_key)
      if downloaded_content == test_content
        puts "✅"
      else
        puts "❌ Downloaded content doesn't match"
        exit 1
      end

      # Test 4: Delete the test file
      print "Testing file deletion... "
      service.delete(test_key)
      puts "✅"

      puts "\n🎉 All S3 tests passed! Your configuration is working correctly."
    end
  rescue => e
    puts "\nPlease check:"
    puts "- Your S3 credentials are correct"
    puts "- The bucket '#{ENV["S3_BUCKET"]}' exists"
    puts "- Your access key has the required permissions"
    puts e.backtrace.first(5) if e.respond_to?(:backtrace)
    exit 1
  end
end
