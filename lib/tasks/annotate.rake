# frozen_string_literal: true

if Rails.env.development?
  namespace :annotate do
    desc "Annotate all models with schema information"
    task models: :environment do
      system("bundle exec annotaterb models")
    end

    desc "Annotate routes with routing information"
    task routes: :environment do
      system("bundle exec annotaterb routes")
    end

    desc "Remove schema annotations from models"
    task remove: :environment do
      system("bundle exec annotaterb models --delete")
    end
  end

  desc "Annotate models with schema information (alias for annotate:models)"
  task annotate: "annotate:models"
end
