class Page < ApplicationRecord
  self.primary_key = "slug"

  validates :slug, presence: true, uniqueness: true
  validates :link_title, presence: true
  validates :content, presence: true

  def to_param
    slug
  end
end
