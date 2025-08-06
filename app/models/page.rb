# typed: true
# frozen_string_literal: true

# == Schema Information
#
# Table name: pages
#
#  content          :text
#  is_snippet       :boolean          default(FALSE), not null
#  link_title       :string
#  meta_description :text
#  meta_title       :string
#  slug             :string           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class Page < ApplicationRecord
  extend T::Sig

  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "slug"

  validates :slug, uniqueness: true

  scope :pages, -> { where(is_snippet: false) }
  scope :snippets, -> { where(is_snippet: true) }

  sig { returns(String) }
  def to_param
    slug.presence || "new"
  end

  # Returns content marked as safe for rendering
  # Page content is admin-controlled and contains intentional HTML
  sig { returns(ActiveSupport::SafeBuffer) }
  def safe_content
    content.to_s.html_safe
  end
end
