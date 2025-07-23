module InspectionsHelper
  def format_inspection_count(user)
    count = user.inspections.count
    t("inspections.count", count: count)
  end

  def inspection_result_badge(inspection)
    case inspection.passed
    when true
      content_tag(:span, t("inspections.status.pass"), class: "pass-badge")
    when false
      content_tag(:span, t("inspections.status.fail"), class: "fail-badge")
    when nil
      content_tag(:span, t("inspections.status.pending"), class: "pending-badge")
    end
  end

  def inspection_actions(inspection)
    actions = []

    if inspection.complete?
      # Complete inspections: Switch to In Progress / Log
      actions << {
        label: t("inspections.buttons.switch_to_in_progress"),
        url: mark_draft_inspection_path(inspection),
        method: :patch,
        confirm: t("inspections.messages.mark_in_progress_confirm"),
        button: true
      }
      actions << {
        label: t("inspections.buttons.log"),
        url: log_inspection_path(inspection)
      }
    else
      # Incomplete inspections: Update Inspection / Log / Delete Inspection
      actions << {
        label: t("inspections.buttons.update"),
        url: edit_inspection_path(inspection)
      }
      actions << {
        label: t("inspections.buttons.log"),
        url: log_inspection_path(inspection)
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
      # For the main inspection tab, check if required fields are filled (excluding passed)
      inspection.inspection_tab_incomplete_fields.empty?
    when "results"
      # For results tab, check if passed field is filled (risk_assessment is optional)
      inspection.passed.present?
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

  def next_incomplete_tab(inspection, current_tab)
    all_tabs = inspection.applicable_tabs
    current_index = all_tabs.index(current_tab)
    return nil unless current_index

    tabs_to_check = all_tabs[(current_index + 1)..]
    next_tab = tabs_to_check.find { |tab|
      !assessment_complete?(inspection, tab)
    }

    return next_tab if next_tab

    if inspection.passed.nil?
      "results"
    end
  end
end
