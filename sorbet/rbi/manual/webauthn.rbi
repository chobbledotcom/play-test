# typed: strict

module WebAuthn
  extend T::Sig
  
  class Credential; end
  class PublicKeyCredential; end
  class AuthenticatorAssertionResponse; end
  class AuthenticatorAttestationResponse; end
  
  class Configuration
    extend T::Sig
    
    sig { returns(T.nilable(String)) }
    attr_accessor :origin
    
    sig { returns(T.nilable(String)) }
    attr_accessor :rp_name
  end
  
  sig { returns(Configuration) }
  def self.configuration; end
  
  sig { params(block: T.proc.params(config: Configuration).void).void }
  def self.configure(&block); end
end