# typed: false

# Slow Test Detector - warns about tests taking more than 2 seconds
# This shim tracks test execution time and warns about slow tests

module SlowTestDetector
  THRESHOLD_SECONDS = 2

  class << self
    attr_accessor :fail_on_slow

    def initialize_tracking
      self.fail_on_slow = ENV["FAIL_ON_SLOW_TESTS"] == "true"
    end

    def track_duration(start_time)
      Time.zone.now - start_time
    end

    def slow?(duration)
      duration > THRESHOLD_SECONDS
    end

    def format_duration(duration)
      "%.2f" % duration
    end

    def print_slow_test(example, duration)
      puts "⚠️  SLOW: #{format_duration(duration)}s - #{example.full_description} (#{example.location})"
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    SlowTestDetector.initialize_tracking
  end

  config.around(:each) do |example|
    start_time = Time.zone.now
    example.run
    duration = SlowTestDetector.track_duration(start_time)

    if SlowTestDetector.slow?(duration)
      SlowTestDetector.print_slow_test(example, duration)
      exit(1) if SlowTestDetector.fail_on_slow
    end
  end
end
