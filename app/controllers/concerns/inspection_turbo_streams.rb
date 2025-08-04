# typed: true
# frozen_string_literal: true

module InspectionTurboStreams
  extend ActiveSupport::Concern
  extend T::Sig

  private

  sig { returns(T::Array[T.untyped]) }
  def success_turbo_streams
    [
      mark_complete_section_stream,
      save_message_stream(success: true),
      assessment_save_message_stream(success: true),
      *photo_update_streams
    ].compact
  end

  sig { returns(T::Array[T.untyped]) }
  def error_turbo_streams
    [
      mark_complete_section_stream,
      save_message_stream(success: false),
      assessment_save_message_stream(success: false)
    ]
  end

  sig { returns(T.untyped) }
  def mark_complete_section_stream
    turbo_stream.replace(
      "mark_complete_section_#{@inspection.id}",
      partial: "inspections/mark_complete_section",
      locals: {inspection: @inspection}
    )
  end

  sig { params(success: T::Boolean).returns(T.untyped) }
  def save_message_stream(success:)
    turbo_stream.replace(
      "inspection_save_message",
      partial: "shared/save_message",
      locals: save_message_locals(
        success: success,
        dom_id: "inspection_save_message"
      )
    )
  end

  sig { params(success: T::Boolean).returns(T.untyped) }
  def assessment_save_message_stream(success:)
    turbo_stream.replace(
      "form_save_message",
      partial: "shared/save_message",
      locals: save_message_locals(success: success, dom_id: "form_save_message")
    )
  end

  sig { params(success: T::Boolean, dom_id: String).returns(T::Hash[Symbol, T.untyped]) }
  def save_message_locals(success:, dom_id:)
    if success
      current_tab_name = params[:tab].presence || "inspection"
      nav_info = helpers.next_tab_navigation_info(@inspection, current_tab_name)

      {
        dom_id: dom_id,
        success: true,
        message: t("inspections.messages.updated"),
        inspection: @inspection
      }.tap do |locals|
        if nav_info
          locals[:next_tab] = nav_info[:tab]
          locals[:skip_incomplete] = nav_info[:skip_incomplete]
          locals[:incomplete_count] = nav_info[:incomplete_count] if nav_info[:skip_incomplete]
        end
      end
    else
      {
        dom_id: dom_id,
        errors: @inspection.errors.full_messages,
        message: t("shared.messages.save_failed")
      }
    end
  end

  sig { returns(T::Array[T.untyped]) }
  def photo_update_streams
    return [] unless params[:inspection]

    %i[photo_1 photo_2 photo_3].filter_map do |photo_field|
      next if params[:inspection][photo_field].blank?

      turbo_stream.replace(
        "inspection_#{photo_field}_field",
        partial: "chobble_forms/file_field_turbo_response",
        locals: {
          model: @inspection,
          field: photo_field,
          turbo_frame_id: "inspection_#{photo_field}_field",
          i18n_base: "forms.results",
          accept: "image/*"
        }
      )
    end
  end
end
