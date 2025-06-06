module InspectionsHelper
  def format_inspection_count(user)
    count = user.inspections.count
    if user.inspection_limit > 0
      "#{count} / #{user.inspection_limit} inspections"
    else
      "#{count} inspections"
    end
  end

  def inspection_links(user)
    total = user.inspections.count
    overdue = user.inspections.overdue.count

    if total > 0
      links = []
      links << link_to("all (#{total})", inspections_path)
      links << link_to("overdue (#{overdue})", overdue_inspections_path) if overdue > 0
      content_tag(:p, links.join(" / ").html_safe, class: "center") if links.any?
    end
  end

  def inspection_result_badge(inspection)
    if inspection.passed
      content_tag(:mark, "PASS")
    else
      content_tag(:mark, "FAIL", style: "background-color:#f2dede;color:#a94442;")
    end
  end

  def inspection_actions(inspection)
    [
      {
        label: "Edit",
        url: edit_inspection_path(inspection)
      }
    ]
  end

  # Tabbed inspection editing helpers
  def inspection_tabs(inspection)
    tabs = %w[general user_height slide structure anchorage materials fan]
    tabs << "enclosed" if inspection.unit&.unit_type == "totally_enclosed"
    tabs
  end

  def current_tab
    params[:tab].presence || "general"
  end

  def assessment_completion_percentage(inspection)
    # Check if inspection has any assessments
    has_assessments = inspection.user_height_assessment.present? ||
      inspection.slide_assessment.present? ||
      inspection.structure_assessment.present? ||
      inspection.anchorage_assessment.present? ||
      inspection.materials_assessment.present? ||
      inspection.fan_assessment.present?

    return 0 unless has_assessments

    total_assessments = inspection_tabs(inspection).count - 1 # Exclude 'general' tab
    return 0 if total_assessments == 0

    completed_assessments = 0
    completed_assessments += 1 if inspection.user_height_assessment&.complete?
    completed_assessments += 1 if inspection.slide_assessment&.complete?
    completed_assessments += 1 if inspection.structure_assessment&.complete?
    completed_assessments += 1 if inspection.anchorage_assessment&.complete?
    completed_assessments += 1 if inspection.materials_assessment&.complete?
    completed_assessments += 1 if inspection.fan_assessment&.complete?
    completed_assessments += 1 if inspection.unit&.unit_type == "totally_enclosed" && inspection.enclosed_assessment&.complete?

    (completed_assessments.to_f / total_assessments * 100).round(0)
  end
end
