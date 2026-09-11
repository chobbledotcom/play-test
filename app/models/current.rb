# typed: strict
# frozen_string_literal: true

# Request-scoped context holding the signed-in user. The executor resets it
# automatically between requests and jobs, so values never leak between them.
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
