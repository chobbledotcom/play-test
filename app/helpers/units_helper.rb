# typed: strict
# frozen_string_literal: true

module UnitsHelper
  extend T::Sig

  sig { params(user: User).returns(T::Array[String]) }
  def manufacturer_options(user)
    user.units.distinct.pluck(:manufacturer).compact.compact_blank.sort
  end

  sig { params(user: User).returns(T::Array[String]) }
  def operator_options(user)
    user.units.distinct.pluck(:operator).compact.compact_blank.sort
  end

  sig { returns(String) }
  def unit_search_placeholder
    serial_label = ChobbleForms::FieldUtils.form_field_label("units", "serial")
    name_label = ChobbleForms::FieldUtils.form_field_label("units", "name")
    "#{serial_label} or #{name_label.downcase}"
  end

  sig {
    params(unit: Unit).returns(
      T::Array[
        T::Hash[Symbol, T.any(String, Symbol, T::Boolean, T::Hash[Symbol, String])]
      ]
    )
  }
  def unit_actions(unit)
    actions = T.let([
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
    ], T::Array[
      T::Hash[Symbol, T.any(String, Symbol, T::Boolean, T::Hash[Symbol, String])]
    ])

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
