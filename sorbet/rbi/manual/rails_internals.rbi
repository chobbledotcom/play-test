# typed: strict

# Rails internals referenced by Tapioca's generated DSL RBIs (columns,
# associations, relations). The Rails gems ship no RBIs of their own, so
# declare the shapes the generated files need; bodies stay empty because
# nothing calls these at runtime.
module ActiveRecord
  class Relation
  end

  class AssociationRelation < Relation
  end

  module Batches
    class BatchEnumerator
    end
  end

  module Associations
    class CollectionProxy
    end
  end

  module Type
    module Binary
      class Data
      end
    end

    module Time
      class Value
      end
    end
  end
end

module ActiveSupport
  module Multibyte
    class Chars
    end
  end
end

module ActionDispatch
  module Routing
    module UrlFor
    end

    module PolymorphicRoutes
    end
  end
end

module ActiveStorage
  module Attached
    class One
    end

    class Many
    end
  end
end

Boolean = T.type_alias { T::Boolean }
