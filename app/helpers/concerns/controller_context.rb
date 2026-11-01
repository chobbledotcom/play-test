# typed: strict
# frozen_string_literal: true

# Provides the controller/request context methods that Rails mixes in when a
# helper module is included in a controller or a view. Helpers only ever run
# in those contexts, so each method forwards to the real implementation.
#
# These declarations are also the only static source of the context methods
# for controllers: this project ships no actionpack gem RBIs, so Sorbet only
# sees them through the helper modules that Tapioca includes into every
# controller. The methods must therefore stay non-abstract - an abstract sig
# here would make every controller an unimplemented interface.
module ControllerContext
  extend T::Sig

  sig { returns(T.untyped) }
  def params
    super
  end

  sig { returns(T.untyped) }
  def session
    super
  end

  sig { returns(T.untyped) }
  def cookies
    super
  end

  sig { returns(T.untyped) }
  def request
    super
  end

  sig { returns(T.untyped) }
  def flash
    super
  end

  sig { params(args: T.untyped).returns(T.untyped) }
  def redirect_to(*args)
    super
  end

  sig { params(args: T.untyped).returns(T.untyped) }
  def render(*args)
    super
  end

  sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
  def respond_to(*args, &block)
    super
  end
end
