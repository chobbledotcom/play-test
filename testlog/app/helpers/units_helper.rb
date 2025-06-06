module UnitsHelper
  def manufacturer_options(user)
    user.units.distinct.pluck(:manufacturer).compact.reject(&:blank?).sort
  end

  def owner_options(user)
    user.units.distinct.pluck(:owner).compact.reject(&:blank?).sort
  end

  def unit_actions(unit)
    [
      {
        label: "Edit",
        url: edit_unit_path(unit)
      },
      {
        label: "PDF Report",
        url: certificate_unit_path(unit),
        target: "_blank"
      },
      {
        label: "Delete",
        url: unit,
        method: :delete,
        danger: true
      },
      {
        label: "Add Inspection",
        url: new_inspection_path(unit_id: unit.id)
      }
    ]
  end
end
