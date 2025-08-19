# typed: strict

# Manual RBI to ensure User associations are recognized
class User < ApplicationRecord
  extend T::Sig
  
  sig { returns(T.any(ActiveRecord::Associations::CollectionProxy, T.untyped)) }
  def inspections; end
  
  sig { returns(T.any(ActiveRecord::Associations::CollectionProxy, T.untyped)) }
  def units; end
  
  sig { returns(T.any(ActiveRecord::Associations::CollectionProxy, T.untyped)) }
  def events; end
  
  sig { returns(T.any(ActiveRecord::Associations::CollectionProxy, T.untyped)) }
  def user_sessions; end
  
  sig { returns(T.any(ActiveRecord::Associations::CollectionProxy, T.untyped)) }
  def credentials; end
  
  sig { returns(T::Boolean) }
  def has_seed_data?; end
end