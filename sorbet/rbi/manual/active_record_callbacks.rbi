# typed: strict

# ActiveRecord callback methods
module ActiveRecord
  module Callbacks
    module ClassMethods
      extend T::Sig
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_create(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_destroy(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_save(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_update(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_validation(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def around_create(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def around_destroy(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def around_save(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def around_update(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def before_create(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def before_destroy(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def before_save(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def before_update(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def before_validation(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_commit(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_rollback(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_initialize(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_find(*args, &block); end
      
      sig { params(args: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_touch(*args, &block); end
    end
  end
end

# Make callbacks available on ActiveRecord::Base
class ActiveRecord::Base
  extend ActiveRecord::Callbacks::ClassMethods
end

# Make callbacks available on concerns
module ActiveSupport
  module Concern
    module ClassMethods
      include ActiveRecord::Callbacks::ClassMethods
    end
  end
end