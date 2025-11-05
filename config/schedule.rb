# typed: false

# Copy environment variables to crontab
ENV.each_key do |key|
  env key.to_sym, ENV[key]
end

set :output, "/rails/log/cron.log"
set :environment, ENV.fetch("RAILS_ENV", "production")

# S3 backup is now handled by Solid Queue recurring tasks (config/recurring.yml)
# Removed duplicate cron schedule to prevent race condition where both cron and
# Solid Queue would trigger the backup at the same time, causing file conflicts
