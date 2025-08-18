# typed: strict

# Error classes
module ActiveModel
  class Error < StandardError; end
  module Errors; end
end

module ActiveRecord
  class RecordNotFound < StandardError; end
end

module ActionDispatch
  class RoutingError < StandardError; end
end

module ActionController
  class InvalidAuthenticityToken < StandardError; end
  class InvalidCrossOriginRequest < StandardError; end
  class ActionControllerError < StandardError; end
  
  class TestRequest < ActionDispatch::Request; end
  class TestResponse < ActionDispatch::Response; end
  
  module Flash
    class FlashHash < Hash
      extend T::Sig
      extend T::Generic
      
      K = type_member
      V = type_member
    end
  end
end

module ActionView
  class ActionViewError < StandardError; end
  class Template; end
  
  module Helpers
    class TagBuilder; end
  end
end

# ActiveSupport additions
module ActiveSupport
  class BacktraceCleaner; end
  class Duration; end
  class Cache
    class Store; end
  end
  class Reloader; end
end

# ActiveStorage additions
module ActiveStorage
  class Service
    class S3Service < Service; end
  end
  
  class Attachment
    class One; end
  end
  
  class VariantRecord < ActiveRecord::Base; end
end

# ActiveRecord additions
module ActiveRecord
  module ConnectionAdapters
    module DatabaseStatements; end
    module SchemaStatements; end
    
    class Connection; end
  end
  
  class Type
    class Value; end
  end
  
  module ClassMethods; end
end

# Rails additions
module Rails
  class Application
    class ApplicationController < ActionController::Base; end
  end
end

# Rack additions
module Rack
  module Cors; end
  module Session; end
  
  class Headers; end
end

# AWS SDK
module Aws
  module S3
    class Client; end
  end
end

# Libraries
module RQRCode
  class QRCode; end
end

module ChunkyPNG
  class Image; end
end

module TTFunk
  class File; end
end

module Mail
  class Message; end
end

# Testing
module ActiveSupport
  module Testing
    module Exceptions; end
  end
end

module Minitest
  class Test; end
end

# Form helpers
module ActionView
  module Helpers
    module FormHelper
      class FormBuilder
        extend T::Sig
        
        sig { returns(T.untyped) }
        def object; end
      end
    end
  end
end

# RuboCop
module RuboCop
  module Cop
    class AutoCorrector; end
  end
end

# Image processing
module ImageProcessing
  class Transformer; end
end

# Constants (if not already defined elsewhere)
unless defined?(REINSPECTION_INTERVAL_DAYS)
  REINSPECTION_INTERVAL_DAYS = 365
end

# ActiveSupport Current
unless defined?(Current)
  class Current < ActiveSupport::CurrentAttributes; end
end

# GlobalID fixes
class GlobalID::SignedGlobalID < GlobalID
  extend T::Sig
  
  sig { params(gid: String, options: T.untyped).returns(T.nilable(GlobalID::SignedGlobalID)) }
  def self.parse(gid, options = {}); end
  
  sig { params(sgid: String, options: T.untyped).returns(T.untyped) }
  def self.find(sgid, options = {}); end
end

# ActionController::Collector
class ActionController::Collector
  extend T::Sig
end

# ActionController::Response
class ActionController::Response < ActionDispatch::Response; end

# Base class if needed
unless defined?(Base)
  class Base; end
end