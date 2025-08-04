# frozen_string_literal: true

class User < ChobbleApp::User
  # Inspection-specific associations
  has_many :inspections, dependent: :destroy
  has_many :units, dependent: :destroy

  belongs_to :inspection_company,
    class_name: "InspectorCompany",
    optional: true

  # Inspection-specific aliases
  alias_method :can_create_inspection?, :is_active?

  # Override company-related methods to use inspection_company
  def has_company?
    inspection_company_id.present? || inspection_company.present?
  end

  def display_phone
    has_company? ? inspection_company.phone : phone
  end

  def display_address
    has_company? ? inspection_company.address : address
  end

  def display_country
    has_company? ? inspection_company.country : country
  end

  def display_postal_code
    has_company? ? inspection_company.postal_code : postal_code
  end

  # Override seed data check
  def has_seed_data?
    units.seed_data.exists? || inspections.seed_data.exists?
  end
end
