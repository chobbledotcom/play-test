# frozen_string_literal: true

if Rails.env.development?
  namespace :annotate do
    desc "Annotate all models with schema information"
    task models: :environment do
      require "annotate/annotate_models"
      AnnotateModels.do_annotations(
        model_dir: "app/models",
        show_indexes: true,
        show_foreign_keys: true,
        format_bare: true,
        classified_sort: true,
        position_in_class: "before",
        position_in_factory: "before",
        position_in_test: "before"
      )
    end

    desc "Remove schema annotations from models"
    task remove: :environment do
      require "annotate/annotate_models"
      AnnotateModels.remove_annotations
    end
  end

  desc "Annotate models with schema information (alias for annotate:models)"
  task annotate: "annotate:models"
end