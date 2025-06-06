module EquipmentHelper
  def equipment_links(user)
    total = user.equipment.count
    overdue = user.equipment.overdue.count

    if total > 0
      links = []
      links << link_to("all (#{total})", equipment_index_path)
      links << link_to("overdue (#{overdue})", overdue_equipment_index_path) if overdue > 0
      content_tag(:p, links.join(" / ").html_safe, class: "center") if links.any?
    end
  end

  def equipment_actions(equipment)
    [
      {
        label: "Edit",
        url: edit_equipment_path(equipment)
      },
      {
        label: "PDF Report",
        url: certificate_equipment_path(equipment),
        target: "_blank"
      },
      {
        label: "Delete",
        url: equipment,
        method: :delete,
        danger: true
      },
      {
        label: "Add Inspection",
        url: new_inspection_path(equipment_id: equipment.id)
      }
    ]
  end
end
