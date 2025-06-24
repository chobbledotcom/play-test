module UnitsHelper
  def manufacturer_options(user)
    user.units.distinct.pluck(:manufacturer).compact.compact_blank.sort
  end

  def owner_options(user)
    user.units.distinct.pluck(:owner).compact.compact_blank.sort
  end

  def unit_actions(unit)
    actions = [
      {
        label: I18n.t("units.buttons.view"),
        url: unit_path(unit, anchor: "inspections")
      },
      {
        label: I18n.t("ui.edit"),
        url: edit_unit_path(unit)
      },
      {
        label: I18n.t("units.buttons.pdf_report"),
        url: unit_path(unit, format: :pdf)
      }
    ]

    # Add activity log link for admins and unit owners
    if current_user && (current_user.admin? || unit.user_id == current_user.id)
      actions << {
        label: I18n.t("units.links.view_log"),
        url: log_unit_path(unit)
      }
    end

    if unit.deletable?
      actions << {
        label: I18n.t("units.buttons.delete"),
        url: unit,
        method: :delete,
        danger: true,
        confirm: I18n.t("units.messages.delete_confirm")
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
