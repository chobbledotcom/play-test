# typed: strict

# ActionController helpers and methods
module ActionController
  class Base
    extend T::Sig
    
    # I18n helpers
    sig { params(key: T.any(String, Symbol), options: T.untyped).returns(String) }
    def t(key, **options); end
    
    sig { params(key: T.any(String, Symbol), options: T.untyped).returns(String) }
    def translate(key, **options); end
    
    sig { params(key: T.any(String, Symbol), count: T.untyped, options: T.untyped).returns(String) }
    def l(key, count = nil, **options); end
    
    sig { params(key: T.any(String, Symbol), count: T.untyped, options: T.untyped).returns(String) }
    def localize(key, count = nil, **options); end
  end
end

# EN14960 CalculatorResponse
module EN14960
  class CalculatorResponse
    extend T::Sig
    
    sig { returns(T.nilable(String)) }
    def value_suffix; end
  end
end