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
        url: unit_path(unit, format: :pdf),
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

  # Tabbed unit editing helpers
  def unit_tabs(unit)
    tabs = %w[general user_height]
    
    # Get last inspection to determine unit characteristics
    last_inspection = unit.last_inspection

    # Only show slide tab for units that have slides
    tabs << "slide" if last_inspection&.has_slide?

    tabs += %w[structure anchorage materials fan]

    # Only show enclosed tab for totally enclosed units
    tabs << "enclosed" if last_inspection&.is_totally_enclosed?

    tabs
  end

  def current_tab
    params[:tab].presence || "general"
  end
end
