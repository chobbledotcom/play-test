# typed: strict

module Sentry
  extend T::Sig
  
  sig { params(exception: T.untyped, kwargs: T.untyped).void }
  def self.capture_exception(exception, **kwargs); end
  
  sig { params(message: String, kwargs: T.untyped).void }
  def self.capture_message(message, **kwargs); end
  
  sig { params(kwargs: T.untyped).void }
  def self.configure_scope(**kwargs); end
  
  sig { returns(T.untyped) }
  def self.configuration; end
  
  class Configuration
    extend T::Sig
    
    sig { returns(T.nilable(String)) }
    attr_accessor :dsn
    
    sig { returns(T.nilable(String)) }
    attr_accessor :environment
  end
  
  module Rails; end
end