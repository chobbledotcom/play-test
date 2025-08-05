namespace :attributions do
  desc "Generate ATTRIBUTIONS.md from cached license data"
  task :generate do
    system("bundle exec licensed cache")
    system("ruby generate_attributions.rb")
    puts "✓ Generated ATTRIBUTIONS.md with #{`wc -l ATTRIBUTIONS.md`.split.first} lines"
  end
end
