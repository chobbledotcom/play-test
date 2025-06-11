class UnitParamsService
  def initialize(params)
    @params = params
  end

  def permitted_params
    @params.require(:unit).permit(permitted_attributes)
  end

  private

  def permitted_attributes
    unit_specific_attributes + copyable_attributes
  end

  def unit_specific_attributes
    %i[
      description
      manufacture_date
      manufacturer
      model
      name
      notes
      owner
      photo
      serial
    ]
  end

  def copyable_attributes
    Unit.new.copyable_attributes_via_reflection
  end
end
