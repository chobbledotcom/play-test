# typed: strict
# frozen_string_literal: true

module InspectionsHelper
  extend T::Sig

  sig { params(user: User).returns(String) }
  def format_inspection_count(user)
    count = user.inspections.count
    t("inspections.count", count: count)
  end

  sig { params(inspection: Inspection).returns(String) }
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

  sig { params(inspection: Inspection).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def inspection_actions(inspection)
    actions = T.let([], T::Array[T::Hash[Symbol, T.untyped]])

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
  sig { params(inspection: Inspection).returns(T::Array[String]) }
  def inspection_tabs(inspection)
    inspection.applicable_tabs
  end

  sig { returns(String) }
  def current_tab
    params[:tab].presence || "inspection"
  end

  sig { params(inspection: Inspection, tab: String).returns(T::Boolean) }
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

  sig { params(inspection: Inspection, tab: String).returns(String) }
  def tab_name_with_check(inspection, tab)
    name = t("forms.#{tab}.header")
    assessment_complete?(inspection, tab) ? "#{name} ✓" : name
  end

  sig { params(inspection: Inspection, current_tab: String).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
  def next_tab_navigation_info(inspection, current_tab)
    # Don't show continue message on results tab
    return nil if current_tab == "results"

    all_tabs = inspection.applicable_tabs
    current_index = all_tabs.index(current_tab)
    return nil unless current_index

    tabs_after = all_tabs[(current_index + 1)..]

    # Check if current tab is incomplete
    current_tab_incomplete = !assessment_complete?(inspection, current_tab)

    # Find first incomplete tab after current (excluding results for now)
    next_incomplete = tabs_after.find { |tab|
      tab != "results" && !assessment_complete?(inspection, tab)
    }

    # If current tab is incomplete and there's a next tab available
    if current_tab_incomplete && tabs_after.any?
      incomplete_count = incomplete_fields_count(inspection, current_tab)

      # If there's an incomplete tab after, user should skip current incomplete
      if next_incomplete
        return {tab: next_incomplete, skip_incomplete: true, incomplete_count: incomplete_count}
      end

      # If results tab is incomplete, user should skip to results
      if tabs_after.include?("results") && inspection.passed.nil?
        return {tab: "results", skip_incomplete: true, incomplete_count: incomplete_count}
      end

      # Don't suggest next tab if it's complete and there are no incomplete tabs
      return nil
    end

    # Current tab is complete, just suggest next incomplete tab
    if next_incomplete
      return {tab: next_incomplete, skip_incomplete: false}
    end

    # Check if results tab is incomplete
    if tabs_after.include?("results") && inspection.passed.nil?
      return {tab: "results", skip_incomplete: false}
    end

    nil
  end

  sig { params(inspection: Inspection, tab: String).returns(Integer) }
  def incomplete_fields_count(inspection, tab)
    @incomplete_fields_cache = T.let(@incomplete_fields_cache, T.nilable(T::Hash[String, Integer])) || {}
    cache_key = "#{inspection.id}_#{tab}"

    @incomplete_fields_cache[cache_key] ||= case tab
    when "inspection"
      inspection.inspection_tab_incomplete_fields.length
    when "results"
      inspection.passed.nil? ? 1 : 0
    else
      assessment = inspection.public_send("#{tab}_assessment")
      if assessment
        grouped = assessment.incomplete_fields_grouped
        grouped.values.sum { |group| group[:fields].length }
      else
        0
      end
    end
  end
end
