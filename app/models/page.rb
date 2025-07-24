class Page < ApplicationRecord
  self.primary_key = "slug"

  validates :slug, presence: true, uniqueness: true
  validates :link_title, presence: true
  validates :content, presence: true

  scope :pages, -> { where(is_snippet: false) }
  scope :snippets, -> { where(is_snippet: true) }

  def to_param
    slug.presence || "new"
  end

  # Returns content marked as safe for rendering
  # Page content is admin-controlled and contains intentional HTML
  def safe_content
    content.to_s.html_safe
  end
end
