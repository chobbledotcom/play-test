class Assessments::FanAssessment < ApplicationRecord
  belongs_to :inspection
  
  validates :inspection_id, presence: true, uniqueness: true
  
  validates :blower_type, presence: true, inclusion: { in: ['centrifugal', 'axial', 'other'] }
  validates :blower_power_rating, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 50 }
  validates :blower_voltage, presence: true, inclusion: { in: [110, 115, 120, 220, 230, 240] }
  validates :blower_current_rating, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :electrical_cord_length, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 200 }
  validates :cord_gauge, presence: true, inclusion: { in: ['12AWG', '14AWG', '16AWG'] }
  validates :gfi_protection, inclusion: { in: [true, false] }
  validates :weatherproof_rating, inclusion: { in: ['IP44', 'IP54', 'IP65', 'NEMA_3R', 'NEMA_4X', 'none'] }
  validates :grounding_verified, inclusion: { in: [true, false] }
  validates :intake_screen_condition, inclusion: { in: ['excellent', 'good', 'fair', 'poor', 'missing'] }
  validates :air_flow_cfm, numericality: { greater_than: 0, less_than_or_equal_to: 5000 }, allow_blank: true
  validates :operating_pressure, numericality: { greater_than: 0, less_than_or_equal_to: 10 }, allow_blank: true
  validates :noise_level_db, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_blank: true
  validates :vibration_level, inclusion: { in: ['minimal', 'moderate', 'excessive'] }, allow_blank: true
  validates :fan_housing_condition, inclusion: { in: ['excellent', 'good', 'fair', 'poor'] }
  validates :motor_condition, inclusion: { in: ['excellent', 'good', 'fair', 'poor'] }
  validates :electrical_connections, inclusion: { in: ['secure', 'loose', 'corroded', 'damaged'] }
  validates :cord_condition, inclusion: { in: ['excellent', 'good', 'fair', 'poor', 'damaged'] }
  validates :plug_condition, inclusion: { in: ['excellent', 'good', 'fair', 'poor', 'damaged'] }
  validates :safety_switches, inclusion: { in: ['present_functional', 'present_nonfunctional', 'missing'] }
  validates :thermal_protection, inclusion: { in: ['present_functional', 'present_nonfunctional', 'missing'] }
  validates :manufacturer_label, inclusion: { in: ['present_legible', 'present_faded', 'missing'] }
  validates :ul_listing, inclusion: { in: ['present', 'missing', 'unknown'] }
  validates :maintenance_schedule, inclusion: { in: ['current', 'overdue', 'none'] }
  
  def critical_issues
    issues = []
    issues << "Missing GFI protection" unless gfi_protection
    issues << "Poor grounding verification" unless grounding_verified
    issues << "Damaged electrical cord" if cord_condition == 'damaged'
    issues << "Damaged electrical plug" if plug_condition == 'damaged'
    issues << "Missing safety switches" if safety_switches == 'missing'
    issues << "Missing thermal protection" if thermal_protection == 'missing'
    issues << "Poor motor condition" if motor_condition == 'poor'
    issues << "Damaged electrical connections" if electrical_connections == 'damaged'
    issues << "Missing intake screen" if intake_screen_condition == 'missing'
    issues << "Excessive vibration" if vibration_level == 'excessive'
    issues << "Poor fan housing condition" if fan_housing_condition == 'poor'
    issues
  end
  
  def electrical_safety_score
    score = 100
    score -= 30 unless gfi_protection
    score -= 25 unless grounding_verified
    score -= 20 if cord_condition == 'damaged'
    score -= 20 if plug_condition == 'damaged'
    score -= 15 if safety_switches == 'missing'
    score -= 15 if thermal_protection == 'missing'
    score -= 10 if electrical_connections == 'damaged'
    [score, 0].max
  end
  
  def mechanical_safety_score
    score = 100
    score -= 25 if motor_condition == 'poor'
    score -= 20 if fan_housing_condition == 'poor'
    score -= 15 if intake_screen_condition == 'missing'
    score -= 15 if vibration_level == 'excessive'
    score -= 10 if intake_screen_condition == 'poor'
    score -= 5 if vibration_level == 'moderate'
    [score, 0].max
  end
  
  def power_adequacy_check
    return 'insufficient_data' if air_flow_cfm.blank? || operating_pressure.blank?
    
    calculated_power = (air_flow_cfm * operating_pressure * 0.000157)
    margin = (blower_power_rating - calculated_power) / blower_power_rating
    
    if margin >= 0.2
      'adequate_with_margin'
    elsif margin >= 0.1
      'adequate_minimal'
    elsif margin >= 0
      'adequate_no_margin'
    else
      'inadequate'
    end
  end
  
  def cord_gauge_adequate?
    return false if electrical_cord_length.blank? || blower_current_rating.blank?
    
    case cord_gauge
    when '12AWG'
      electrical_cord_length <= 100 || blower_current_rating <= 20
    when '14AWG'
      electrical_cord_length <= 50 && blower_current_rating <= 15
    when '16AWG'
      electrical_cord_length <= 25 && blower_current_rating <= 10
    else
      false
    end
  end
  
  def environmental_protection_adequate?
    return true if weatherproof_rating.in?(['IP54', 'IP65', 'NEMA_4X'])
    return true if weatherproof_rating.in?(['IP44', 'NEMA_3R']) && indoor_use_only?
    false
  end
  
  def noise_compliance?
    return true if noise_level_db.blank?
    noise_level_db <= 85
  end
  
  def maintenance_current?
    maintenance_schedule == 'current'
  end
  
  def assessment_complete?
    required_fields = [
      :blower_type, :blower_power_rating, :blower_voltage, :blower_current_rating,
      :electrical_cord_length, :cord_gauge, :gfi_protection, :grounding_verified,
      :intake_screen_condition, :fan_housing_condition, :motor_condition,
      :electrical_connections, :cord_condition, :plug_condition, :safety_switches,
      :thermal_protection, :manufacturer_label, :ul_listing, :maintenance_schedule
    ]
    
    required_fields.all? { |field| self.send(field).present? }
  end
  
  def overall_safety_rating
    return 'incomplete' unless assessment_complete?
    return 'fail' if critical_issues.any?
    
    electrical_score = electrical_safety_score
    mechanical_score = mechanical_safety_score
    overall_score = (electrical_score + mechanical_score) / 2
    
    case overall_score
    when 90..100
      'excellent'
    when 80..89
      'good'
    when 70..79
      'fair'
    when 60..69
      'poor'
    else
      'fail'
    end
  end
  
  private
  
  def indoor_use_only?
    inspection&.equipment_location == 'indoor'
  end
end