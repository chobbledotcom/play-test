# typed: false
# frozen_string_literal: true

class TestAliasing
  # This SHOULD be detected - simple alias passing same args
  def fetch_user(id)
    get_user(id)
  end

  # This SHOULD be detected - multiple args passed through
  def find_record(type, id)
    lookup_record(type, id)
  end

  # This should NOT be detected - different args
  def full_name
    format_name(first_name, last_name)
  end

  # This should NOT be detected - no args
  def complete?
    incomplete_fields.empty?
  end

  # This should NOT be detected - receiver present
  def user_name
    user.name
  end

  # This should NOT be detected - comparison not aliasing
  def triggered_by?(check_user)
    user == check_user
  end
end
