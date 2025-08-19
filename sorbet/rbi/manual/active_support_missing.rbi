# typed: strict

module ActiveSupport
  class ArrayInquirer < Array; end
  class StringInquirer < String; end
  class SafeBuffer < String; end
  class TimeZone; end
  class TimeWithZone; end
  
  class HashWithIndifferentAccess < Hash
    extend T::Sig
    extend T::Generic
    
    K = type_member
    V = type_member
  end
  
  module Multibyte
    class Chars; end
  end
end

module DateAndTime
  module Zones; end
  module Calculations; end
end