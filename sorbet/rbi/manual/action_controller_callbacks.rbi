# typed: strong
# frozen_string_literal: true

# Type definitions for ActionController callback methods
module ActionController::Callbacks::ClassMethods
  sig { params(names: T.untyped, block: T.untyped).void }
  def before_action(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def skip_before_action(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def after_action(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def skip_after_action(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def around_action(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def skip_around_action(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def append_before_action(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def prepend_before_action(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def append_after_action(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def prepend_after_action(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def append_around_action(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def prepend_around_action(*names, &block); end
  
  # Aliases for Rails 4 compatibility
  sig { params(names: T.untyped, block: T.untyped).void }
  def before_filter(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def skip_before_filter(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def after_filter(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def skip_after_filter(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def around_filter(*names, &block); end
  
  sig { params(names: T.untyped, block: T.untyped).void }
  def skip_around_filter(*names, &block); end
end

class ActionController::Base
  extend ActionController::Callbacks::ClassMethods
end

class ApplicationController < ActionController::Base
  # ApplicationController inherits all the callback methods
end