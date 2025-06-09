namespace :standard do
  desc "Lint Ruby code with Standard Ruby"
  task :check do
    sh "bundle exec standardrb"
  end

  desc "Autocorrect Ruby code with Standard Ruby"
  task :fix do
    sh "bundle exec standardrb --fix"
  end
end
