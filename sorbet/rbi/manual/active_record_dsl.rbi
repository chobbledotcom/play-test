# typed: strong
# frozen_string_literal: true

# Type annotations for ActiveRecord DSL methods
class ApplicationRecord < ActiveRecord::Base
  extend ActiveRecord::Associations::ClassMethods
  extend ActiveRecord::Validations::ClassMethods  
  extend ActiveRecord::Callbacks::ClassMethods
  extend ActiveRecord::Scoping::Named::ClassMethods
  extend ActiveModel::SecurePassword::ClassMethods
  extend ActiveStorage::Attached::Model
end

module ActiveRecord::Scoping::Named::ClassMethods
  sig { params(name: Symbol, body: T.untyped, block: T.untyped).void }
  def scope(name, body, &block); end
  
  sig { params(scope: T.untyped, all_queries: T::Boolean, block: T.untyped).void }
  def default_scope(scope = nil, all_queries: false, &block); end
end

module ActiveRecord::Associations::ClassMethods
  sig { params(name: Symbol, scope: T.untyped, options: T.untyped, extension: T.untyped).void }
  def has_many(name, scope = nil, **options, &extension); end
  
  sig { params(name: Symbol, scope: T.untyped, options: T.untyped).void }
  def has_one(name, scope = nil, **options); end
  
  sig { params(name: Symbol, scope: T.untyped, options: T.untyped).void }
  def belongs_to(name, scope = nil, **options); end
end

module ActiveRecord::Validations::ClassMethods
  sig { params(attributes: Symbol, options: T.untyped).void }
  def validates(*attributes, **options); end
  
  sig { params(args: T.untyped, block: T.untyped).void }
  def validate(*args, &block); end
end

module ActiveRecord::Callbacks::ClassMethods
  sig { params(args: T.untyped, options: T.untyped, block: T.untyped).void }
  def before_save(*args, **options, &block); end
  
  sig { params(args: T.untyped, options: T.untyped, block: T.untyped).void }
  def before_create(*args, **options, &block); end
  
  sig { params(args: T.untyped, options: T.untyped, block: T.untyped).void }
  def after_save(*args, **options, &block); end
  
  sig { params(args: T.untyped, options: T.untyped, block: T.untyped).void }
  def after_create(*args, **options, &block); end
  
  sig { params(args: T.untyped, options: T.untyped, block: T.untyped).void }
  def after_initialize(*args, **options, &block); end
end

module ActiveModel::SecurePassword::ClassMethods
  sig { params(attribute: Symbol).void }
  def has_secure_password(attribute = :password); end
end

module ActiveStorage::Attached::Model
  sig { params(name: Symbol, dependent: Symbol, service: T.untyped, strict_loading: T::Boolean).void }
  def has_one_attached(name, dependent: :purge_later, service: nil, strict_loading: false); end
  
  sig { params(name: Symbol, dependent: Symbol, service: T.untyped, strict_loading: T::Boolean).void }
  def has_many_attached(name, dependent: :purge_later, service: nil, strict_loading: false); end
end

# ActiveRecord::Base class methods
class ActiveRecord::Base
  class << self
    # Query methods
    sig { params(args: T.untyped).returns(T.untyped) }
    def where(*args); end
    
    sig { returns(T.untyped) }
    def all; end
    
    sig { params(args: T.untyped).returns(T.untyped) }
    def find(*args); end
    
    sig { params(args: T.untyped).returns(T.nilable(T.untyped)) }
    def find_by(*args); end
    
    sig { params(n: T.nilable(Integer)).returns(T.untyped) }
    def first(n = nil); end
    
    sig { params(n: T.nilable(Integer)).returns(T.untyped) }
    def last(n = nil); end
    
    sig { params(args: T.untyped).returns(T.untyped) }
    def order(*args); end
    
    sig { params(value: Integer).returns(T.untyped) }
    def limit(value); end
    
    sig { params(value: Integer).returns(T.untyped) }
    def offset(value); end
    
    sig { params(args: T.untyped).returns(T.untyped) }
    def includes(*args); end
    
    sig { params(args: T.untyped).returns(T.untyped) }
    def joins(*args); end
    
    sig { params(column_names: T.untyped).returns(T::Array[T.untyped]) }
    def pluck(*column_names); end
    
    sig { params(column_name: T.nilable(T.any(String, Symbol))).returns(Integer) }
    def count(column_name = nil); end
  end
  
  # Instance methods
  sig { params(attributes: T.untyped).returns(T::Boolean) }
  def update(attributes); end
  
  sig { params(options: T.untyped).returns(T::Boolean) }
  def save(**options); end
  
  sig { returns(T.self_type) }
  def destroy; end
  
  sig { returns(T::Boolean) }
  def persisted?; end
  
  sig { returns(T::Boolean) }
  def new_record?; end
  
  sig { returns(T.nilable(T.any(String, Integer))) }
  def id; end
  
  sig { returns(T::Hash[String, T.untyped]) }
  def attributes; end
  
  sig { returns(ActiveModel::Errors) }
  def errors; end
  
  sig { params(context: T.nilable(Symbol)).returns(T::Boolean) }
  def valid?(context = nil); end
end