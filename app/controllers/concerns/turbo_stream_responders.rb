# typed: true
# frozen_string_literal: true

module TurboStreamResponders
  extend ActiveSupport::Concern
  extend T::Sig

  private

  sig { params(success: T::Boolean, message: String, model: T.nilable(ActiveRecord::Base), additional_streams: T::Array[Turbo::Streams::TagBuilder]).void }
  def render_save_message_stream(success:, message:, model: nil, additional_streams: [])
    streams = [
      turbo_stream.replace(
        "form_save_message",
        partial: "shared/save_message",
        locals: {
          message: message,
          type: success ? "success" : "error",
          errors: success ? nil : model&.errors&.full_messages
        }
      )
    ]

    streams.concat(additional_streams) if additional_streams.any?

    render turbo_stream: streams
  end

  sig { params(model: ActiveRecord::Base, message_key: T.nilable(String), redirect_path: T.any(String, ActiveRecord::Base, NilClass), additional_streams: T::Array[Turbo::Streams::TagBuilder]).void }
  def handle_update_success(model, message_key = nil, redirect_path = nil, additional_streams: [])
    message_key ||= "#{model.class.table_name}.messages.updated"
    redirect_path ||= model

    respond_to do |format|
      format.html do
        flash[:notice] = I18n.t(message_key)
        redirect_to redirect_path
      end
      format.turbo_stream do
        render_save_message_stream(
          success: true,
          message: I18n.t(message_key),
          additional_streams: additional_streams
        )
      end
    end
  end

  sig { params(model: ActiveRecord::Base, view: Symbol, block: T.nilable(T.proc.params(format: T.untyped).void)).void }
  def handle_update_failure(model, view = :edit, &block)
    respond_to do |format|
      format.html { render view, status: :unprocessable_content }
      format.json do
        render json: {
          status: I18n.t("shared.api.error"),
          errors: model.errors.full_messages
        }
      end
      format.turbo_stream do
        render_save_message_stream(
          success: false,
          message: I18n.t("shared.messages.save_failed"),
          model: model
        )
      end
      yield(format) if block_given?
    end
  end

  sig { params(model: ActiveRecord::Base, message_key: T.nilable(String)).void }
  def handle_create_success(model, message_key = nil)
    message_key ||= "#{model.class.table_name}.messages.created"
    respond_to do |format|
      format.html do
        flash[:notice] = I18n.t(message_key)
        redirect_to model
      end
      format.turbo_stream do
        render_save_message_stream(
          success: true,
          message: I18n.t(message_key)
        )
      end
    end
  end

  sig { params(model: ActiveRecord::Base, view: Symbol).void }
  def handle_create_failure(model, view = :new)
    respond_to do |format|
      format.html { render view, status: :unprocessable_content }
      format.turbo_stream do
        render_save_message_stream(
          success: false,
          message: I18n.t("shared.messages.save_failed"),
          model: model
        )
      end
    end
  end
end
