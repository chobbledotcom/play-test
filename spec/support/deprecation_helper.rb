# Helper for printing detailed deprecation warnings in tests
module DeprecationHelper
  def print_deprecation(message, trait_name: nil)
    # Search through the call stack to find the first spec file
    found = false
    caller_locations.each_with_index do |location, index|
      path = location.path

      # Skip non-spec files and internal Ruby locations
      next if path.start_with?("<internal:")
      next unless path.include?("/spec/") || path.include?("_spec.rb")
      next if path.include?("/factories/")
      next if path.include?("/support/")

      # Found the spec file where the factory was called
      relative_path = begin
        Pathname.new(path).relative_path_from(Rails.root).to_s
      rescue
        path
      end

      # Build deprecation message
      deprecation_parts = ["[DEPRECATION]"]
      deprecation_parts << "Called from #{relative_path}:#{location.lineno}"
      deprecation_parts << "trait :#{trait_name}" if trait_name
      deprecation_parts << message

      warn deprecation_parts.join(" ")
      found = true
      break
    end

    # If we can't find a spec file, show trait info at least
    unless found
      if trait_name
        warn "[DEPRECATION] trait :#{trait_name} #{message}"
      else
        warn "[DEPRECATION] #{message}"
      end
    end
  end

  # Convenience method for deprecating factory traits
  def deprecate_trait(trait_name, message)
    print_deprecation(message, trait_name: trait_name)
  end
end

# Include in FactoryBot to make it available in factory definitions
if defined?(FactoryBot)
  FactoryBot::SyntaxRunner.include(DeprecationHelper)
end
