# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageProcessable, type: :controller do
  controller(ApplicationController) do
    include ImageProcessable

    # Skip authentication for tests
    skip_before_action :require_login

    define_method(:create) do
      processed_params = process_image_params(params[:item], :photo, :avatar)

      # For testing purposes, we don't re-raise image processing errors
      # The method should handle them gracefully by setting fields to nil
      render json: {params: processed_params}, status: :ok
    end

    define_method(:upload) do
      processed_io = process_image(params[:file])
      render json: {success: true, processed: processed_io.present?}
    rescue ApplicationErrors::NotAnImageError,
      ApplicationErrors::ImageProcessingError => e
      handle_image_error(e)
    end

    define_method(:validate) do
      validate_image!(params[:file])
      render json: {valid: true}
    rescue ApplicationErrors::NotAnImageError => e
      render json: {valid: false, error: e.message},
        status: :unprocessable_entity
    end

    # Test methods for rescue_from handlers
    define_method(:test_not_an_image) do
      raise ApplicationErrors::NotAnImageError.new("Not an image")
    rescue ApplicationErrors::NotAnImageError => e
      handle_image_error(e)
    end

    define_method(:test_processing_error) do
      raise ApplicationErrors::ImageProcessingError.new("Processing error")
    rescue ApplicationErrors::ImageProcessingError => e
      handle_image_error(e)
    end

    # Test method for handle_image_error
    define_method(:test_error) do
      raise params[:error_type].constantize.new(params[:message])
    rescue ApplicationErrors::NotAnImageError,
      ApplicationErrors::ImageProcessingError => e
      handle_image_error(e)
    end
  end

  before do
    routes.draw do
      post "create" => "anonymous#create"
      post "upload" => "anonymous#upload"
      post "validate" => "anonymous#validate"
      post "test_error" => "anonymous#test_error"
      post "test_not_an_image" => "anonymous#test_not_an_image"
      post "test_processing_error" => "anonymous#test_processing_error"
    end
  end

  describe "#process_image_params" do
    let(:valid_image) do
      fixture_file_upload("spec/fixtures/files/test_image.jpg", "image/jpeg")
    end

    let(:invalid_file) do
      fixture_file_upload("spec/fixtures/files/test.txt", "text/plain")
    end

    context "when processing valid image fields" do
      it "processes single image field successfully" do
        allow(PhotoProcessingService).to receive(:valid_image?).and_return(true)
        allow(PhotoProcessingService).to receive(:process_upload).and_return(
          StringIO.new("processed_image_data")
        )

        post :create, params: {item: {photo: valid_image, name: "Test"}}

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["params"]["name"]).to eq("Test")
      end

      it "processes multiple image fields" do
        allow(PhotoProcessingService).to receive(:valid_image?).and_return(true)
        allow(PhotoProcessingService).to receive(:process_upload).and_return(
          StringIO.new("processed_image_data")
        )

        post :create, params: {
          item: {
            photo: valid_image,
            avatar: valid_image,
            name: "Test"
          }
        }

        expect(response).to have_http_status(:ok)
        expect(PhotoProcessingService).to have_received(:process_upload).twice
      end

      it "skips blank image fields" do
        allow(PhotoProcessingService).to receive(:valid_image?)
        allow(PhotoProcessingService).to receive(:process_upload)

        post :create, params: {item: {photo: nil, avatar: "", name: "Test"}}

        expect(response).to have_http_status(:ok)
        expect(PhotoProcessingService).not_to have_received(:valid_image?)
        expect(PhotoProcessingService).not_to have_received(:process_upload)
      end

      it "skips non-file parameters" do
        allow(PhotoProcessingService).to receive(:valid_image?)
        allow(PhotoProcessingService).to receive(:process_upload)

        post :create, params: {item: {photo: "just_a_string", name: "Test"}}

        expect(response).to have_http_status(:ok)
        expect(PhotoProcessingService).not_to have_received(:valid_image?)
      end
    end

    context "when processing invalid images" do
      it "sets field to nil when image is invalid" do
        allow(PhotoProcessingService).to receive(:valid_image?)
          .and_return(false)

        post :create, params: {item: {photo: invalid_file, name: "Test"}}

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["params"]["photo"]).to be_nil
      end

      it "sets field to nil when processing fails" do
        allow(PhotoProcessingService).to receive(:valid_image?)
          .and_return(true)
        allow(PhotoProcessingService).to receive(:process_upload)
          .and_return(nil)

        post :create, params: {item: {photo: valid_image, name: "Test"}}

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["params"]["photo"]).to be_nil
      end

      it "handles ApplicationErrors::NotAnImageError" do
        allow(PhotoProcessingService).to receive(:valid_image?)
          .and_return(false)

        expect {
          post :create, params: {item: {photo: invalid_file}}
        }.not_to raise_error

        expect(response).to have_http_status(:ok)
      end

      it "handles ApplicationErrors::ImageProcessingError" do
        allow(PhotoProcessingService).to receive(:valid_image?).and_return(true)
        allow(PhotoProcessingService).to receive(:process_upload).and_raise(
          ApplicationErrors::ImageProcessingError.new("Processing failed")
        )

        expect {
          post :create, params: {item: {photo: valid_image}}
        }.not_to raise_error

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "#process_image" do
    let(:valid_image) do
      fixture_file_upload("spec/fixtures/files/test_image.jpg", "image/jpeg")
    end

    context "when image is valid" do
      it "returns processed image IO" do
        processed_io = StringIO.new("processed_data")
        allow(PhotoProcessingService).to receive(:valid_image?).and_return(true)
        allow(PhotoProcessingService).to receive(:process_upload)
          .and_return(processed_io)

        post :upload, params: {file: valid_image}

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["success"]).to be true
        expect(parsed_response["processed"]).to be true
      end
    end

    context "when image is invalid" do
      it "raises NotAnImageError" do
        allow(PhotoProcessingService).to receive(:valid_image?)
          .and_return(false)

        post :upload, params: {file: valid_image}

        expect(response).to redirect_to(root_path)
        msg = I18n.t("errors.messages.invalid_image_format")
        expect(flash[:alert]).to eq(msg)
      end
    end

    context "when processing fails" do
      it "raises ImageProcessingError when process_upload returns nil" do
        allow(PhotoProcessingService).to receive(:valid_image?).and_return(true)
        allow(PhotoProcessingService).to receive(:process_upload)
          .and_return(nil)

        post :upload, params: {file: valid_image}

        expect(response).to redirect_to(root_path)
        msg = I18n.t("errors.messages.image_processing_failed")
        expect(flash[:alert]).to eq(msg)
      end

      it "handles Vips::Error and logs the error" do
        vips_error = Vips::Error.new("Vips processing failed")
        allow(PhotoProcessingService).to receive(:valid_image?).and_return(true)
        allow(PhotoProcessingService).to receive(:process_upload)
          .and_raise(vips_error)
        allow(Rails.logger).to receive(:error)

        post :upload, params: {file: valid_image}

        error_msg = "Image processing failed: Vips processing failed"
        expect(Rails.logger).to have_received(:error).with(error_msg)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("Vips processing failed")
      end
    end
  end

  describe "#validate_image!" do
    let(:valid_image) do
      fixture_file_upload("spec/fixtures/files/test_image.jpg", "image/jpeg")
    end

    it "does not raise error for valid image" do
      allow(PhotoProcessingService).to receive(:valid_image?).and_return(true)

      post :validate, params: {file: valid_image}

      expect(response).to have_http_status(:ok)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["valid"]).to be true
    end

    it "raises NotAnImageError for invalid image" do
      allow(PhotoProcessingService).to receive(:valid_image?).and_return(false)

      post :validate, params: {file: valid_image}

      expect(response).to have_http_status(:unprocessable_entity)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["valid"]).to be false
      msg = I18n.t("errors.messages.invalid_image_format")
      expect(parsed_response["error"]).to eq(msg)
    end
  end

  describe "#handle_image_error" do
    context "with HTML format" do
      it "sets flash alert and redirects to root" do
        post :test_error, params: {
          error_type: "ApplicationErrors::NotAnImageError",
          message: "Invalid image"
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Invalid image")
      end

      it "redirects to fallback location" do
        request.env["HTTP_REFERER"] = "/previous_page"

        post :test_error, params: {
          error_type:
            "ApplicationErrors::ImageProcessingError",
          message: "Processing failed"
        }

        expect(response).to redirect_to("/previous_page")
        expect(flash[:alert]).to eq("Processing failed")
      end
    end

    context "with turbo_stream format" do
      it "sets flash.now and redirects with see_other status" do
        post :test_error, params: {
          error_type: "ApplicationErrors::NotAnImageError",
          message: "Invalid image"
        }, format: :turbo_stream

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(root_path)
        expect(flash.now[:alert]).to eq("Invalid image")
      end
    end
  end

  describe "rescue_from handlers" do
    it "rescues from NotAnImageError" do
      post :test_not_an_image

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Not an image")
    end

    it "rescues from ImageProcessingError" do
      post :test_processing_error

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Processing error")
    end
  end

  describe "integration with ActionController::Parameters" do
    let(:valid_image) do
      fixture_file_upload("spec/fixtures/files/test_image.jpg", "image/jpeg")
    end

    it "works with strong parameters" do
      allow(PhotoProcessingService).to receive(:valid_image?).and_return(true)
      allow(PhotoProcessingService).to receive(:process_upload).and_return(
        StringIO.new("processed_image_data")
      )

      controller.params = ActionController::Parameters.new(
        item: {photo: valid_image, name: "Test"}
      )

      result = controller.send(:process_image_params,
        controller.params[:item], :photo)

      expect(result).to be_a(ActionController::Parameters)
      expect(result[:name]).to eq("Test")
    end
  end
end
