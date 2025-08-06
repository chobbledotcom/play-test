# == Schema Information
#
# Table name: credentials
#
#  id          :integer          not null, primary key
#  nickname    :string           not null
#  public_key  :string           not null
#  sign_count  :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  external_id :string           not null
#  user_id     :string(12)       not null
#
# Indexes
#
#  index_credentials_on_external_id  (external_id) UNIQUE
#  index_credentials_on_user_id      (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
require "rails_helper"

RSpec.describe Credential, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
