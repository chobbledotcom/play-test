class Equipment < ApplicationRecord
  belongs_to :user
  has_many :inspections, dependent: :nullify

  before_create :generate_id

  validates :name, :location, :serial, presence: true

  def self.search(query)
    where("serial LIKE ? OR name LIKE ?", "%#{query}%", "%#{query}%")
  end

  def self.overdue
    where(id: Equipment.joins(:inspections)
      .select("equipment.id")
      .where("inspections.reinspection_date < ?", Date.today)
      .group("equipment.id"))
  end

  def last_due_date
    inspections.order(created_at: :desc).first&.reinspection_date
  end

  private

  def generate_id
    self.id = SecureRandom.alphanumeric(12).downcase if id.nil?
  end
end
