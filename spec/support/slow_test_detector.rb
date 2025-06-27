# Slow Test Detector - warns about tests taking more than 0.5 seconds
# This shim tracks test execution time and warns about slow tests

module SlowTestDetector
  class << self
    attr_accessor :suite_start_time, :slow_examples, :slow_example_groups, :context_timers, :fail_on_slow

    def initialize_tracking
      self.suite_start_time = Time.zone.now
      self.slow_examples = []
      self.slow_example_groups = []
      self.context_timers = {}
      self.fail_on_slow = ENV["FAIL_ON_SLOW_TESTS"] == "true"
    end
  end
end

RSpec.configure do |config|
  # Initialize tracking at suite start
  config.before(:suite) do
    SlowTestDetector.initialize_tracking
  end

  # Track timing for individual examples
  config.around(:each) do |example|
    start_time = Time.zone.now
    example.run
    duration = Time.zone.now - start_time

    if duration > 0.5
      SlowTestDetector.slow_examples << {
        description: example.full_description,
        location: example.location,
        duration: duration
      }
    end
  end

  # Track timing for example groups (describe/context blocks)
  config.before(:context) do |example_group|
    # Store the start time for this specific context
    context_id = example_group.class.object_id
    SlowTestDetector.context_timers[context_id] = Time.zone.now
  end

  config.after(:context) do |example_group|
    context_id = example_group.class.object_id
    start_time = SlowTestDetector.context_timers[context_id]

    if start_time
      duration = Time.zone.now - start_time
      SlowTestDetector.context_timers.delete(context_id)

      if duration > 0.5
        # Get the description from the example group metadata
        group_description = example_group.class.metadata[:full_description] ||
          example_group.class.metadata[:description] ||
          example_group.class.name

        example_count = example_group.class.descendants.sum { |c| c.filtered_examples.count }

        SlowTestDetector.slow_example_groups << {
          description: group_description,
          location: example_group.class.metadata[:location],
          duration: duration,
          example_count: example_count
        }

        # Immediate warning for slow example groups
        puts "\n⚠️  SLOW TEST CLASS: #{group_description}"
        puts "   Duration: #{"%.2f" % duration}s (threshold: 0.5s)"
        puts "   Location: #{example_group.class.metadata[:location]}"
        puts "   Examples in group: #{example_count}"
      end
    end
  end

  # Summary report at the end
  config.after(:suite) do
    if SlowTestDetector.suite_start_time
      suite_duration = Time.zone.now - SlowTestDetector.suite_start_time
      has_slow_tests = false

      if SlowTestDetector.slow_example_groups.any?
        has_slow_tests = true
        puts "\n" + "=" * 80
        puts "SLOW TEST CLASSES SUMMARY (> 0.5s)"
        puts "=" * 80

        SlowTestDetector.slow_example_groups.sort_by { |g| -g[:duration] }.each_with_index do |group, index|
          puts "\n#{index + 1}. #{group[:description]}"
          puts "   Duration: #{"%.2f" % group[:duration]}s"
          puts "   Location: #{group[:location]}"
          puts "   Examples: #{group[:example_count]}"
        end
      end

      if SlowTestDetector.slow_examples.any?
        has_slow_tests = true
        puts "\n" + "=" * 80
        puts "SLOW INDIVIDUAL TESTS SUMMARY (> 0.5s)"
        puts "=" * 80

        SlowTestDetector.slow_examples.sort_by { |e| -e[:duration] }.first(10).each_with_index do |example, index|
          puts "\n#{index + 1}. #{example[:description]}"
          puts "   Duration: #{"%.2f" % example[:duration]}s"
          puts "   Location: #{example[:location]}"
        end

        if SlowTestDetector.slow_examples.count > 10
          puts "\n... and #{SlowTestDetector.slow_examples.count - 10} more slow tests"
        end
      end

      puts "\n" + "=" * 80
      puts "Total suite duration: #{"%.2f" % suite_duration}s"
      puts "=" * 80

      # Fail if slow tests detected and FAIL_ON_SLOW_TESTS is set
      if has_slow_tests && SlowTestDetector.fail_on_slow
        puts "\n" + "=" * 80
        puts "❌ TESTS FAILED: Slow tests detected (threshold: 0.5s)"
        puts "Set FAIL_ON_SLOW_TESTS=false to allow slow tests"
        puts "=" * 80
        exit(1)
      end
    end
  end
end
