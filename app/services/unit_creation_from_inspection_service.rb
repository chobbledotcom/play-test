# typed: true
# frozen_string_literal: true

class UnitCreationFromInspectionService
  extend T::Sig

  sig { returns(T::Array[String]) }
  attr_reader :errors

  sig { params(user: User, inspection_id: String, unit_params: ActionController::Parameters).void }
  def initialize(user:, inspection_id:, unit_params:)
    @user = user
    @inspection_id = inspection_id
    @unit_params = unit_params
    @errors = []
  end

  sig { returns(T::Boolean) }
  def create
    return false unless validate_inspection

    @unit = @user.units.build(@unit_params)
    if @unit.save
      @inspection.update!(unit: @unit)
      true
    else
      false
    end
  end

  sig { returns(T.nilable(Inspection)) }
  attr_reader :inspection

  sig { returns(T.nilable(Unit)) }
  attr_reader :unit

  sig { returns(T.nilable(String)) }
  def error_message
    @errors.first
  end

  private

  sig { returns(T::Boolean) }
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
