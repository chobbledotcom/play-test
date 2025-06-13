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

    # Only show update link if inspection is not complete
    unless inspection.complete?
      actions << {
        label: t("inspections.buttons.update"),
        url: edit_inspection_path(inspection)
      }
    end

    # Show delete action if inspection is not complete OR user is admin
    if !inspection.complete? || current_user.admin?
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
    tabs = %w[general user_height]

    # Only show slide tab for inspections that have slides
    if inspection.has_slide?
      tabs << "slide"
    end

    tabs += %w[structure anchorage materials fan]

    # Only show enclosed tab for totally enclosed inspections
    tabs << "enclosed" if inspection.is_totally_enclosed?

    tabs
  end

  def current_tab
    params[:tab].presence || "general"
  end

  def assessment_completion_percentage(inspection)
    # Check if inspection has any assessments
    has_assessments = inspection.user_height_assessment.present? ||
      inspection.structure_assessment.present? ||
      inspection.anchorage_assessment.present? ||
      inspection.materials_assessment.present? ||
      inspection.fan_assessment.present?

    # Also check conditional assessments
    if inspection.has_slide?
      has_assessments ||= inspection.slide_assessment.present?
    end
    if inspection.is_totally_enclosed?
      has_assessments ||= inspection.enclosed_assessment.present?
    end

    return 0 unless has_assessments

    total_assessments = inspection_tabs(inspection).count - 1 # Exclude 'general' tab
    return 0 if total_assessments == 0

    completed_assessments = 0
    completed_assessments += 1 if inspection.user_height_assessment&.complete?
    completed_assessments += 1 if inspection.structure_assessment&.complete?
    completed_assessments += 1 if inspection.anchorage_assessment&.complete?
    completed_assessments += 1 if inspection.materials_assessment&.complete?
    completed_assessments += 1 if inspection.fan_assessment&.complete?

    # Only count slide assessment if inspection has a slide
    if inspection.has_slide?
      completed_assessments += 1 if inspection.slide_assessment&.complete?
    end

    # Only count enclosed assessment if inspection is totally enclosed
    if inspection.is_totally_enclosed?
      completed_assessments += 1 if inspection.enclosed_assessment&.complete?
    end

    (completed_assessments.to_f / total_assessments * 100).round(0)
  end
end
