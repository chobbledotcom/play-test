# typed: strict
# frozen_string_literal: true

# Provides Sorbet type declarations for Rails controller methods
# that are available when a helper module is included in a controller.
# Include this concern in any helper that needs access to controller methods.
module ControllerContext
  extend T::Sig
  extend T::Helpers

  # These methods are provided by ActionController, so we just need
  # to declare their signatures for Sorbet without marking them abstract

  sig { returns(T.untyped) }
  def session
  end

  sig { returns(T.untyped) }
  def cookies
  end

  sig { returns(T.untyped) }
  def params
  end

  sig { returns(T.untyped) }
  def request
  end

  sig { returns(T.untyped) }
  def flash
  end

  sig { params(args: T.untyped).returns(T.untyped) }
  def redirect_to(*args)
  end

  sig { params(args: T.untyped).returns(T.untyped) }
  def render(*args)
  end

  sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
  def respond_to(*args, &block)
  end
end
