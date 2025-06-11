class UnitCreationFromInspectionService
  attr_reader :errors

  def initialize(user:, inspection_id:, unit_params:)
    @user = user
    @inspection_id = inspection_id
    @unit_params = unit_params
    @errors = []
  end

  def create
    return false unless validate_inspection

    @unit = @user.units.build(@unit_params)
    @unit.copy_attributes_from(@inspection)

    if @unit.save
      @inspection.update!(unit: @unit)
      true
    else
      false
    end
  end

  attr_reader :inspection

  attr_reader :unit

  def error_message
    @errors.first
  end

  private

  def validate_inspection
    @inspection = @user.inspections.find_by(id: @inspection_id)

    unless @inspection
      @errors << I18n.t("units.errors.inspection_not_found")
      return false
    end

    if @inspection.unit
      @errors << I18n.t("units.errors.inspection_has_unit")
      return false
    end

    true
  end
end
