# Copy environment variables to crontab
ENV.each_key do |key|
  env key.to_sym, ENV[key]
end

set :output, "/rails/log/cron.log"
set :environment, ENV.fetch("RAILS_ENV", "production")
# Set the job_template to ensure we're in the right directory
set :job_template, "cd :path && :environment_variable=:environment bundle exec :task :output"

every 1.day, at: "2:00 am" do
  rake "s3:backup:database", environment: :production
end

# Temporary debug task - run every 5 minutes for testing
every 5.minutes do
  rake "debug:cron", environment: :production
end
