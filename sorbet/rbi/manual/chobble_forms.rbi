# typed: strict

# ChobbleForms module and its utilities
module ChobbleForms
  class FieldUtils
    extend T::Sig

    sig { params(field: T.any(Symbol, String)).returns(T::Boolean) }
    def self.is_comment_field?(field); end

    sig { params(field: T.any(Symbol, String)).returns(T::Boolean) }
    def self.is_pass_field?(field); end

    sig { params(field: T.any(Symbol, String)).returns(Symbol) }
    def self.strip_field_suffix(field); end
  end
end