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
end
