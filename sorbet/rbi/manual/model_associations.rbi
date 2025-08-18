# typed: strict

# Additional model associations and methods not captured by Tapioca

class User < ApplicationRecord
  extend T::Sig
  
  sig { returns(T.nilable(InspectorCompany)) }
  def inspection_company; end
  
  sig { params(value: T.nilable(InspectorCompany)).void }
  def inspection_company=(value); end
end

class Inspection < ApplicationRecord
  extend T::Sig
  
  # Attributes from database
  sig { returns(T.nilable(DateTime)) }
  def complete_date; end
  
  sig { params(value: T.nilable(DateTime)).void }
  def complete_date=(value); end
  
  sig { returns(T.nilable(DateTime)) }
  def inspection_date; end
  
  sig { params(value: T.nilable(DateTime)).void }
  def inspection_date=(value); end
  
  sig { returns(T.nilable(Float)) }
  def length; end
  
  sig { params(value: T.nilable(Float)).void }
  def length=(value); end
  
  sig { returns(T.nilable(Float)) }
  def width; end
  
  sig { params(value: T.nilable(Float)).void }
  def width=(value); end
  
  sig { returns(T.nilable(Float)) }
  def height; end
  
  sig { params(value: T.nilable(Float)).void }
  def height=(value); end
  
  sig { returns(T::Boolean) }
  def has_slide; end
  
  sig { params(value: T::Boolean).void }
  def has_slide=(value); end
  
  sig { returns(T::Boolean) }
  def has_slide?; end
  
  sig { returns(T::Boolean) }
  def is_totally_enclosed; end
  
  sig { params(value: T::Boolean).void }
  def is_totally_enclosed=(value); end
  
  sig { returns(T::Boolean) }
  def is_totally_enclosed?; end
  
  sig { returns(T::Boolean) }
  def indoor_only; end
  
  sig { params(value: T::Boolean).void }
  def indoor_only=(value); end
  
  sig { returns(T::Boolean) }
  def indoor_only?; end
  
  sig { returns(T::Boolean) }
  def passed; end
  
  sig { params(value: T::Boolean).void }
  def passed=(value); end
  
  sig { returns(T::Boolean) }
  def bouncing_pillow?; end
  
  # Associations
  sig { returns(T.nilable(Unit)) }
  def unit; end
  
  sig { params(value: T.nilable(Unit)).void }
  def unit=(value); end
  
  # ActiveRecord methods
  sig { params(args: T.untyped).void }
  def update!(args); end
  
  sig { returns(T::Boolean) }
  def complete?; end
end