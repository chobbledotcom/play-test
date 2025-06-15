module InspectionsHelper
  def format_inspection_count(user)
    count = user.inspections.count
    "#{count} inspections"
  end

  def inspection_result_badge(inspection)
    if inspection.passed
      content_tag(:mark, "PASS")
    else
      content_tag(:mark, "FAIL", style: "background-color:#f2dede;color:#a94442;")
    end
  end

  def inspection_actions(inspection)
    actions = []

    # Regular users cannot edit or delete complete inspections
    if inspection.complete?
      # Only admins can delete complete inspections
      if current_user&.admin?
        actions << {
          label: t("inspections.buttons.delete"),
          url: inspection_path(inspection),
          method: :delete,
          confirm: t("inspections.messages.delete_confirm"),
          danger: true
        }
      end
    else
      # Non-complete inspections can be edited and deleted
      actions << {
        label: t("inspections.buttons.update"),
        url: edit_inspection_path(inspection)
      }
      actions << {
        label: t("inspections.buttons.delete"),
        url: inspection_path(inspection),
        method: :delete,
        confirm: t("inspections.messages.delete_confirm"),
        danger: true
      }
    end

    actions
  end

  # Tabbed inspection editing helpers
  def inspection_tabs(inspection)
    # Use the model's applicable_tabs method but rename "inspection" to "inspections" 
    # for consistency with existing view code
    inspection.applicable_tabs.map { |tab| tab == "inspection" ? "inspections" : tab }
  end

  def current_tab
    params[:tab].presence || "inspections"
  end
end
