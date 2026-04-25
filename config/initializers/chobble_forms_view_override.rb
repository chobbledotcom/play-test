# typed: false
# frozen_string_literal: true

# chobble-forms' engine prepends its own view path, which would otherwise
# beat any app-level overrides (e.g. our typed-schema-aware version of
# chobble_forms/_fields.html.erb). Re-prepend the app view path after the
# engine has loaded so app overrides win.
Rails.application.config.after_initialize do
  ActionController::Base.prepend_view_path(
    Rails.root.join("app/views")
  )
end
