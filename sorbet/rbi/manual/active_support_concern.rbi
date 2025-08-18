# typed: strong
# frozen_string_literal: true

# Type definitions for ActiveSupport::Concern
module ActiveSupport
  module Concern
    sig { params(base: T.untyped).void }
    def self.extended(base); end
    
    sig { params(block: T.proc.void).void }
    def class_methods(&block); end
    
    sig { params(block: T.proc.void).void }
    def included(&block); end
    
    sig { params(block: T.proc.void).void }
    def prepended(&block); end
  end
end