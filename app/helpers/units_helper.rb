module UnitsHelper
  def manufacturer_options(user)
    user.units.distinct.pluck(:manufacturer).compact.reject(&:blank?).sort
  end

  def owner_options(user)
    user.units.distinct.pluck(:owner).compact.reject(&:blank?).sort
  end

  def unit_actions(unit)
    actions = [
      {
        label: I18n.t("ui.edit"),
        url: edit_unit_path(unit)
      },
      {
        label: I18n.t("units.buttons.pdf_report"),
        url: report_unit_path(unit),
        target: "_blank"
      }
    ]

    if unit.deletable?
      actions << {
        label: I18n.t("units.buttons.delete"),
        url: unit,
        method: :delete,
        danger: true
      }
    end

    actions << {
      label: I18n.t("units.buttons.add_inspection"),
      url: inspections_path,
      method: :post,
      params: {unit_id: unit.id},
      confirm: I18n.t("units.messages.add_inspection_confirm")
    }

    actions
  end
end
