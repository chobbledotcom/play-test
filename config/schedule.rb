# Copy environment variables to crontab
ENV.each_key do |key|
  env key.to_sym, ENV[key]
end

set :output, "/rails/log/cron.log"
set :environment, ENV.fetch("RAILS_ENV", "production")

every 1.day, at: "2:00 am" do
  rake "s3:backup:database"
end
