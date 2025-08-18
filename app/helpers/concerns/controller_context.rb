# typed: strict
# frozen_string_literal: true

# Provides Sorbet type declarations for Rails controller methods
# that are available when a helper module is included in a controller.
# Include this concern in any helper that needs access to controller methods.
module ControllerContext
  extend T::Sig
  extend T::Helpers

  abstract!

  # These methods are provided by ActionController/ActionView
  # We declare them as abstract so Sorbet knows about them
  # but doesn't provide implementations that would override Rails

  sig { abstract.returns(T.untyped) }
  def session
  end

  sig { abstract.returns(T.untyped) }
  def cookies
  end

  sig { abstract.returns(T.untyped) }
  def params
  end

  sig { abstract.returns(T.untyped) }
  def request
  end

  sig { abstract.returns(T.untyped) }
  def flash
  end

  sig { abstract.params(args: T.untyped).returns(T.untyped) }
  def redirect_to(*args)
  end

  sig { abstract.params(args: T.untyped).returns(T.untyped) }
  def render(*args)
  end

  sig { abstract.params(args: T.untyped, block: T.untyped).returns(T.untyped) }
  def respond_to(*args, &block)
  end
end
