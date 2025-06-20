module InspectionsHelper
  def format_inspection_count(user)
    count = user.inspections.count
    t("inspections.count", count: count)
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
    inspection.applicable_tabs
  end

  def current_tab
    params[:tab].presence || "inspection"
  end

  def assessment_complete?(inspection, tab)
    case tab
    when "inspection"
      # For the main inspection tab, check if required fields are filled
      inspection.inspection_model_incomplete_fields.empty?
    else
      # For assessment tabs, check the corresponding assessment
      assessment_method = "#{tab}_assessment"
      assessment = inspection.public_send(assessment_method)
      assessment&.complete? || false
    end
  end

  def tab_name_with_check(inspection, tab)
    name = t("forms.#{tab}.header")
    assessment_complete?(inspection, tab) ? "#{name} ✓" : name
  end
end
