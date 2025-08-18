# typed: strict

# Prosopite for N+1 query detection
module Prosopite
  extend T::Sig
  
  sig { params(block: T.proc.void).void }
  def self.scan(&block); end
  
  sig { void }
  def self.finish; end
  
  sig { returns(T::Boolean) }
  def self.enabled?; end
end

# MissionControl for job monitoring
module MissionControl
  module Jobs
    class Engine < ::Rails::Engine; end
  end
end

# Blueprinter for JSON serialization
module Blueprinter
  class Base
    extend T::Sig
    
    sig { params(object: T.untyped, options: T.untyped).returns(String) }
    def self.render(object, options = {}); end
    
    sig { params(objects: T.untyped, options: T.untyped).returns(String) }
    def self.render_as_hash(objects, options = {}); end
  end
end

# Vips for image processing
module Vips
  class Image
    extend T::Sig
    
    sig { params(filename: String).returns(Vips::Image) }
    def self.new_from_file(filename); end
    
    sig { params(filename: String, kwargs: T.untyped).void }
    def write_to_file(filename, **kwargs); end
  end
end

# Turbo Rails
module Turbo
  module Native
    module Navigation; end
  end
  
  module Streams
    module ActionHelper; end
    module Broadcasts; end
  end
end

# Rack
module Rack
  class Request
    extend T::Sig
    
    sig { returns(T::Hash[String, T.untyped]) }
    def env; end
  end
  
  class Response
    extend T::Sig
    
    sig { returns(Integer) }
    attr_accessor :status
    
    sig { returns(T::Hash[String, String]) }
    def headers; end
  end
end

# ActiveRecord Connection
module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      extend T::Sig
    end
    
    class PostgreSQLAdapter < AbstractAdapter; end
    class SQLite3Adapter < AbstractAdapter; end
  end
end

# ActiveStorage Blob
module ActiveStorage
  class Blob < ActiveRecord::Base
    extend T::Sig
    
    sig { returns(T.nilable(String)) }
    def key; end
    
    sig { returns(T.nilable(String)) }
    def filename; end
  end
  
  class Current < ActiveSupport::CurrentAttributes
    extend T::Sig
    
    sig { returns(T.nilable(String)) }
    def self.url_options; end
  end
  
  class Service
    extend T::Sig
    
    sig { params(key: String).returns(T.nilable(String)) }
    def url(key); end
  end
end

# ActiveSupport Notifications
module ActiveSupport
  module Notifications
    extend T::Sig
    
    sig { params(name: String, block: T.proc.void).void }
    def self.instrument(name, &block); end
    
    sig { params(pattern: T.any(String, Regexp), block: T.proc.void).void }
    def self.subscribe(pattern, &block); end
  end
  
  class Current < CurrentAttributes; end
  
  class CurrentAttributes
    extend T::Sig
  end
  
  class Logger < ::Logger
    extend T::Sig
  end
  
  module TaggedLogging
    extend T::Sig
    
    module Formatter; end
  end
end

# GlobalID
module GlobalID
  class SignedGlobalID
    extend T::Sig
    
    sig { params(gid: String, options: T.untyped).returns(T.nilable(SignedGlobalID)) }
    def self.parse(gid, options = {}); end
  end
end

# ActionView helpers
module ActionView
  module Helpers
    module TagHelper
      extend T::Sig
      
      sig { params(name: T.any(Symbol, String), content_or_options: T.untyped, options: T.untyped, block: T.nilable(T.proc.void)).returns(ActiveSupport::SafeBuffer) }
      def content_tag(name, content_or_options = nil, options = nil, &block); end
    end
  end
end

# Error class placeholder
class Error < StandardError; end

# Constants for assessments
REINSPECTION_INTERVAL_DAYS = 365

# Prism LexCompat
module Prism
  module LexCompat
    class Result; end
  end
end

# RBS module placeholders (for RBI gem compatibility)
module RBS
  module Types
    class Alias; end
    module Bases
      class Any; end
      class Bool; end
      class Bottom; end
      class Class; end
      class Instance; end
      class Nil; end
      class Self; end
      class Top; end
      class Void; end
    end
    class ClassInstance; end
    class ClassSingleton; end
    class Function; end
    class Interface; end
    class Intersection; end
    class Literal; end
    class Optional; end
    class Proc; end
    class Record; end
    class Tuple; end
    class Union; end
    class UntypedFunction; end
    class Variable; end
    class Block; end
    module Function
      class Param; end
    end
  end
  class MethodType; end
end

# RBI TypedParam
module RBI
  class TypedParam; end
end

# ActionController Collector
module ActionController
  class Collector; end
end

# ActiveRecord Base transaction
class ActiveRecord::Base
  extend T::Sig
  
  sig { params(block: T.proc.void).void }
  def self.transaction(&block); end
end