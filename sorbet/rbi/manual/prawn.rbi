# typed: strict

module Prawn
  class Document
    extend T::Sig
    
    sig { params(options: T.untyped).void }
    def initialize(options = {}); end
    
    sig { params(text: String, options: T.untyped).void }
    def text(text, options = {}); end
    
    sig { params(data: T::Array[T::Array[T.untyped]], options: T.untyped).void }
    def table(data, options = {}); end
    
    sig { returns(String) }
    def render; end
    
    sig { params(file: String).void }
    def render_file(file); end
  end
  
  module View
    extend T::Sig
    
    sig { returns(Prawn::Document) }
    def document; end
  end
end