class Assessments::EnclosedAssessment < ApplicationRecord
  belongs_to :inspection
  
  validates :inspection_id, presence: true, uniqueness: true
  
  validates :enclosure_type, presence: true, inclusion: { in: ['full_enclosure', 'partial_enclosure', 'canopy_only'] }
  validates :ceiling_height, presence: true, numericality: { greater_than: 1.5, less_than_or_equal_to: 10.0 }
  validates :floor_area_sqm, presence: true, numericality: { greater_than: 4, less_than_or_equal_to: 500 }
  validates :occupancy_limit, presence: true, numericality: { greater_than: 1, less_than_or_equal_to: 100 }
  validates :ventilation_type, presence: true, inclusion: { in: ['natural', 'forced_air', 'hybrid', 'none'] }
  validates :air_changes_per_hour, numericality: { greater_than: 0, less_than_or_equal_to: 20 }, allow_blank: true
  validates :emergency_exits, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :exit_width_cm, presence: true, numericality: { greater_than: 60, less_than_or_equal_to: 300 }
  validates :exit_visibility, inclusion: { in: ['clearly_marked', 'poorly_marked', 'unmarked'] }
  validates :emergency_lighting, inclusion: { in: ['present_functional', 'present_nonfunctional', 'missing'] }
  validates :fire_extinguisher, inclusion: { in: ['present_current', 'present_expired', 'missing'] }
  validates :first_aid_kit, inclusion: { in: ['present_stocked', 'present_incomplete', 'missing'] }
  validates :supervision_visibility, inclusion: { in: ['excellent', 'good', 'limited', 'obstructed'] }
  validates :internal_obstacles, inclusion: { in: ['none', 'minimal', 'moderate', 'excessive'] }
  validates :ceiling_attachments, inclusion: { in: ['secure', 'loose', 'damaged', 'missing'] }
  validates :wall_attachments, inclusion: { in: ['secure', 'loose', 'damaged', 'missing'] }
  validates :structural_integrity, inclusion: { in: ['excellent', 'good', 'fair', 'poor'] }
  validates :material_flame_rating, inclusion: { in: ['class_a', 'class_b', 'class_c', 'untested', 'non_compliant'] }
  validates :seam_construction, inclusion: { in: ['welded', 'sewn_reinforced', 'sewn_basic', 'bonded', 'poor'] }
  validates :transparency_panels, inclusion: { in: ['clear_undamaged', 'scratched', 'cracked', 'missing', 'none'] }
  validates :interior_temperature, numericality: { greater_than: -10, less_than_or_equal_to: 50 }, allow_blank: true
  validates :humidity_level, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_blank: true
  validates :air_quality, inclusion: { in: ['excellent', 'good', 'fair', 'poor'] }, allow_blank: true
  validates :noise_level_interior, numericality: { greater_than: 0, less_than_or_equal_to: 120 }, allow_blank: true
  validates :cleaning_schedule, inclusion: { in: ['daily', 'weekly', 'monthly', 'as_needed', 'none'] }
  validates :sanitization_protocol, inclusion: { in: ['comprehensive', 'basic', 'minimal', 'none'] }
  validates :maintenance_access, inclusion: { in: ['excellent', 'good', 'limited', 'poor'] }
  validates :equipment_storage, inclusion: { in: ['designated_area', 'mixed_storage', 'no_storage'] }
  
  def critical_safety_issues
    issues = []
    issues << "Insufficient emergency exits for occupancy" unless adequate_exit_capacity?
    issues << "Exit width below minimum requirements" if exit_width_cm < 90
    issues << "Emergency exits unmarked" if exit_visibility == 'unmarked'
    issues << "Missing emergency lighting" if emergency_lighting == 'missing'
    issues << "Missing fire extinguisher" if fire_extinguisher == 'missing'
    issues << "Poor structural integrity" if structural_integrity == 'poor'
    issues << "Damaged ceiling attachments" if ceiling_attachments == 'damaged'
    issues << "Damaged wall attachments" if wall_attachments == 'damaged'
    issues << "Non-compliant fire rating" if material_flame_rating == 'non_compliant'
    issues << "Inadequate ventilation" unless adequate_ventilation?
    issues << "Excessive interior temperature" if interior_temperature.present? && interior_temperature > 35
    issues << "Obstructed supervision visibility" if supervision_visibility == 'obstructed'
    issues << "Excessive internal obstacles" if internal_obstacles == 'excessive'
    issues
  end
  
  def adequate_exit_capacity?
    return false if emergency_exits.blank? || occupancy_limit.blank?
    
    required_exits = case occupancy_limit
    when 1..10
      1
    when 11..25
      2
    when 26..50
      3
    when 51..75
      4
    else
      5
    end
    
    emergency_exits >= required_exits
  end
  
  def adequate_ventilation?
    return false if ventilation_type == 'none'
    return true if ventilation_type == 'natural' && ceiling_height > 2.5
    return true if ventilation_type.in?(['forced_air', 'hybrid']) && air_changes_per_hour.present? && air_changes_per_hour >= 4
    false
  end
  
  def space_density_compliant?
    return false if floor_area_sqm.blank? || occupancy_limit.blank?
    
    sqm_per_person = floor_area_sqm / occupancy_limit
    sqm_per_person >= 2.0
  end
  
  def ceiling_height_adequate?
    return false if ceiling_height.blank?
    
    case enclosure_type
    when 'full_enclosure'
      ceiling_height >= 2.1
    when 'partial_enclosure'
      ceiling_height >= 1.8
    when 'canopy_only'
      ceiling_height >= 2.0
    else
      false
    end
  end
  
  def environmental_conditions_acceptable?
    temp_ok = interior_temperature.blank? || interior_temperature.between?(15, 30)
    humidity_ok = humidity_level.blank? || humidity_level.between?(30, 70)
    air_ok = air_quality.blank? || air_quality.in?(['excellent', 'good'])
    noise_ok = noise_level_interior.blank? || noise_level_interior <= 85
    
    temp_ok && humidity_ok && air_ok && noise_ok
  end
  
  def fire_safety_rating
    score = 100
    score -= 40 if material_flame_rating == 'non_compliant'
    score -= 30 if fire_extinguisher == 'missing'
    score -= 25 if emergency_lighting == 'missing'
    score -= 20 if material_flame_rating == 'untested'
    score -= 15 if fire_extinguisher == 'present_expired'
    score -= 15 if emergency_lighting == 'present_nonfunctional'
    score -= 10 if exit_visibility == 'unmarked'
    score -= 5 if exit_visibility == 'poorly_marked'
    [score, 0].max
  end
  
  def structural_safety_rating
    score = 100
    score -= 30 if structural_integrity == 'poor'
    score -= 25 if ceiling_attachments == 'damaged'
    score -= 25 if wall_attachments == 'damaged'
    score -= 20 if structural_integrity == 'fair'
    score -= 15 if ceiling_attachments == 'loose'
    score -= 15 if wall_attachments == 'loose'
    score -= 10 if seam_construction == 'poor'
    score -= 5 if seam_construction == 'bonded'
    [score, 0].max
  end
  
  def occupancy_safety_rating
    score = 100
    score -= 30 unless adequate_exit_capacity?
    score -= 25 if supervision_visibility == 'obstructed'
    score -= 20 unless space_density_compliant?
    score -= 15 if internal_obstacles == 'excessive'
    score -= 10 if supervision_visibility == 'limited'
    score -= 10 if internal_obstacles == 'moderate'
    score -= 5 if first_aid_kit != 'present_stocked'
    [score, 0].max
  end
  
  def ventilation_rating
    score = 100
    score -= 50 if ventilation_type == 'none'
    score -= 30 unless adequate_ventilation?
    score -= 20 unless environmental_conditions_acceptable?
    score -= 15 if air_quality == 'poor'
    score -= 10 if air_quality == 'fair'
    [score, 0].max
  end
  
  def maintenance_hygiene_rating
    score = 100
    score -= 25 if cleaning_schedule == 'none'
    score -= 20 if sanitization_protocol == 'none'
    score -= 15 if maintenance_access == 'poor'
    score -= 15 if cleaning_schedule == 'as_needed'
    score -= 10 if sanitization_protocol == 'minimal'
    score -= 10 if maintenance_access == 'limited'
    score -= 5 if equipment_storage == 'no_storage'
    [score, 0].max
  end
  
  def assessment_complete?
    required_fields = [
      :enclosure_type, :ceiling_height, :floor_area_sqm, :occupancy_limit,
      :ventilation_type, :emergency_exits, :exit_width_cm, :exit_visibility,
      :emergency_lighting, :fire_extinguisher, :first_aid_kit, :supervision_visibility,
      :internal_obstacles, :ceiling_attachments, :wall_attachments, :structural_integrity,
      :material_flame_rating, :seam_construction, :transparency_panels, :cleaning_schedule,
      :sanitization_protocol, :maintenance_access, :equipment_storage
    ]
    
    required_fields.all? { |field| self.send(field).present? }
  end
  
  def overall_safety_rating
    return 'incomplete' unless assessment_complete?
    return 'fail' if critical_safety_issues.any?
    
    fire_score = fire_safety_rating
    structural_score = structural_safety_rating
    occupancy_score = occupancy_safety_rating
    ventilation_score = ventilation_rating
    maintenance_score = maintenance_hygiene_rating
    
    overall_score = (fire_score + structural_score + occupancy_score + ventilation_score + maintenance_score) / 5
    
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
  
  def compliance_checklist
    {
      ceiling_height_adequate: ceiling_height_adequate?,
      space_density_compliant: space_density_compliant?,
      adequate_exits: adequate_exit_capacity?,
      adequate_ventilation: adequate_ventilation?,
      fire_safety_compliant: fire_safety_rating >= 70,
      structural_integrity_good: structural_safety_rating >= 70,
      environmental_acceptable: environmental_conditions_acceptable?,
      maintenance_adequate: maintenance_hygiene_rating >= 70
    }
  end
end