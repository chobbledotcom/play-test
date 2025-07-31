set :output, "/rails/log/cron.log"
set :environment, ENV.fetch("RAILS_ENV", "production")

every 1.day, at: "2:00 am" do
  rake "s3:backup:database"
end
