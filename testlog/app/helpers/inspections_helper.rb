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
    actions = [
      {
        label: "Edit",
        url: edit_inspection_path(inspection)
      }
    ]

    if inspection.equipment.present?
      actions << {
        label: "New Inspection",
        url: new_inspection_path(equipment_id: inspection.equipment.id)
      }
    end

    actions
  end
end
