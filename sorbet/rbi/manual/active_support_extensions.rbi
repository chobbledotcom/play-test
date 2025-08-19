# typed: strict

# ActiveSupport extensions to core Ruby classes

class Date
  extend T::Sig
  
  sig { returns(Date) }
  def self.current; end
  
  sig { returns(Date) }
  def self.today; end
  
  sig { returns(Date) }
  def self.tomorrow; end
  
  sig { returns(Date) }
  def self.yesterday; end
end

class Integer
  extend T::Sig
  
  sig { returns(ActiveSupport::Duration) }
  def days; end
  
  sig { returns(ActiveSupport::Duration) }
  def hours; end
  
  sig { returns(ActiveSupport::Duration) }
  def minutes; end
  
  sig { returns(ActiveSupport::Duration) }
  def seconds; end
  
  sig { returns(ActiveSupport::Duration) }
  def weeks; end
  
  sig { returns(ActiveSupport::Duration) }
  def months; end
  
  sig { returns(ActiveSupport::Duration) }
  def years; end
  
  sig { returns(ActiveSupport::Duration) }
  def day; end
  
  sig { returns(ActiveSupport::Duration) }
  def hour; end
  
  sig { returns(ActiveSupport::Duration) }
  def minute; end
  
  sig { returns(ActiveSupport::Duration) }
  def second; end
  
  sig { returns(ActiveSupport::Duration) }
  def week; end
  
  sig { returns(ActiveSupport::Duration) }
  def month; end
  
  sig { returns(ActiveSupport::Duration) }
  def year; end
end

module ActiveSupport
  class Duration
    extend T::Sig
    
    sig { returns(Float) }
    def to_f; end
    
    sig { returns(Integer) }
    def to_i; end
    
    sig { params(time: T.any(Time, Date, DateTime)).returns(T.any(Time, Date, DateTime)) }
    def ago(time = Time.current); end
    
    sig { params(time: T.any(Time, Date, DateTime)).returns(T.any(Time, Date, DateTime)) }
    def since(time = Time.current); end
    
    sig { params(time: T.any(Time, Date, DateTime)).returns(T.any(Time, Date, DateTime)) }
    def from_now(time = Time.current); end
    
    sig { params(time: T.any(Time, Date, DateTime)).returns(T.any(Time, Date, DateTime)) }
    def before(time); end
    
    sig { params(time: T.any(Time, Date, DateTime)).returns(T.any(Time, Date, DateTime)) }
    def after(time); end
  end
end