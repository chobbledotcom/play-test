#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "pathname"

# Script to copy infrastructure files from the gem to a new Chobble app
class InfrastructureSetup
  def self.setup(target_root = Dir.pwd)
    gem_root = File.expand_path("..", __FILE__)
    
    puts "Setting up Chobble infrastructure in #{target_root}..."
    
    # Copy Docker files
    copy_file(gem_root, target_root, "Dockerfile")
    copy_file(gem_root, target_root, ".dockerignore")
    
    # Copy linter configs
    copy_file(gem_root, target_root, ".rubocop.yml")
    copy_file(gem_root, target_root, ".standard.yml")
    copy_file(gem_root, target_root, ".erb_lint.yml")
    copy_file(gem_root, target_root, ".better-html.yml")
    
    # Copy GitHub workflows
    FileUtils.mkdir_p(File.join(target_root, ".github/workflows"))
    Dir.glob(File.join(gem_root, ".github/workflows/*.yml")).each do |workflow|
      copy_file(gem_root, target_root, ".github/workflows/#{File.basename(workflow)}")
    end
    
    # Copy bin scripts
    FileUtils.mkdir_p(File.join(target_root, "bin"))
    Dir.glob(File.join(gem_root, "bin/*")).each do |script|
      target_path = File.join(target_root, "bin", File.basename(script))
      FileUtils.cp(script, target_path)
      FileUtils.chmod(0755, target_path)
      puts "  Copied bin/#{File.basename(script)}"
    end
    
    puts "\nInfrastructure setup complete!"
    puts "\nYou may need to:"
    puts "  - Update the Dockerfile if your app has specific dependencies"
    puts "  - Modify GitHub workflows for your deployment needs"
    puts "  - Adjust linter configs to your preferences"
  end
  
  private
  
  def self.copy_file(source_root, target_root, relative_path)
    source = File.join(source_root, relative_path)
    target = File.join(target_root, relative_path)
    
    if File.exist?(source)
      FileUtils.cp(source, target)
      puts "  Copied #{relative_path}"
    else
      puts "  WARNING: #{relative_path} not found in gem"
    end
  end
end

# Run if called directly
if __FILE__ == $0
  target = ARGV[0] || Dir.pwd
  InfrastructureSetup.setup(target)
end