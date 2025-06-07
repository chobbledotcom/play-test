# RPII Utility - Primary inspection management
class InspectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inspection, only: [:show, :edit, :update, :destroy]
  before_action :validate_rpii_credentials, only: [:create, :update]

  # GET /inspections
  # Dashboard showing all inspections with search/filter
  def index
    @inspections = current_user.inspections
                              .includes(:unit, :inspector_company)
                              .search(params[:search])
                              .filter_by_status(params[:status])
                              .order(created_at: :desc)
                              .page(params[:page])
  end

  # GET /inspections/new
  # Multi-step inspection creation wizard
  def new
    @inspection = current_user.inspections.build
    @inspection.build_unit
    @inspection.build_user_height_assessment
    @inspection.build_slide_assessment
    @inspection.build_structure_assessment
    @inspection.build_anchorage_assessment
    @inspection.build_materials_assessment
    @inspection.build_fan_assessment
    @inspection.inspection_date = Date.current
  end

  # POST /inspections
  # Create new inspection with comprehensive validation
  def create
    @inspection = current_user.inspections.build(inspection_params)

    if @inspection.save
      redirect_to edit_inspection_path(@inspection),
                  notice: 'Inspection created. Complete all assessment sections.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /inspections/:id/edit
  # Tabbed editing interface matching Windows Forms layout
  def edit
    @current_tab = params[:tab] || 'unit_details'
    @validation_errors = @inspection.validate_completeness
  end

  # PATCH /inspections/:id
  # Update with auto-save capability and validation
  def update
    if @inspection.update(inspection_params)
      if params[:auto_save]
        render json: { status: 'saved', errors: [] }
      else
        redirect_to inspection_path(@inspection),
                    notice: 'Inspection updated successfully.'
      end
    else
      if params[:auto_save]
        render json: { status: 'error', errors: @inspection.errors.full_messages }
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  # GET /inspections/:id
  # View completed inspection with pass/fail determination
  def show
    @pdf_url = inspection_report_path(@inspection, format: :pdf)
  end

  # DELETE /inspections/:id
  # Soft delete with audit trail
  def destroy
    @inspection.update(deleted_at: Time.current, deleted_by: current_user)
    redirect_to inspections_path, notice: 'Inspection deleted.'
  end

  # POST /inspections/:id/finalize
  # Lock inspection and generate final pass/fail
  def finalize
    if @inspection.can_be_finalized?
      @inspection.finalize!(current_user)
      redirect_to @inspection, notice: 'Inspection finalized.'
    else
      redirect_to edit_inspection_path(@inspection),
                  alert: 'Cannot finalize: incomplete assessment sections.'
    end
  end

  # GET /inspections/:id/duplicate
  # Create copy for similar equipment inspections
  def duplicate
    @new_inspection = @inspection.duplicate_for_user(current_user)
    redirect_to edit_inspection_path(@new_inspection)
  end

  private

  def set_inspection
    @inspection = current_user.inspections.find(params[:id])
  end

  def inspection_params
    params.require(:inspection).permit(
      # Global details
      :inspection_company_name, :rpii_registration_number, :place_inspected,
      :inspection_date, :testimony, :passed, :risk_assessment,

      # Unit details
      unit_attributes: [:id, :description, :manufacturer, :width, :length, :height,
                       :serial_number, :unit_type, :owner, :photo],

      # All assessment attributes (150+ fields)
      user_height_assessment_attributes: [:id, :containing_wall_height,
                                        :containing_wall_height_comment, :platform_height,
                                        :platform_height_comment, :slide_barrier_height,
                                        # ... all height assessment fields
                                       ],

      slide_assessment_attributes: [:id, :slide_platform_height, :slide_wall_height,
                                   # ... all slide assessment fields
                                  ],

      structure_assessment_attributes: [:id, :seam_integrity_pass, :seam_integrity_comment,
                                       # ... all structure assessment fields
                                      ],

      anchorage_assessment_attributes: [:id, :num_low_anchors, :num_high_anchors,
                                       # ... all anchorage assessment fields
                                      ],

      materials_assessment_attributes: [:id, :rope_size, :rope_size_pass,
                                       # ... all materials assessment fields
                                      ],

      fan_assessment_attributes: [:id, :blower_size_comment, :blower_flap_pass,
                                 # ... all fan assessment fields
                                ]
    )
  end

  def validate_rpii_credentials
    unless current_user.valid_rpii_inspector?
      redirect_to root_path, alert: 'Valid RPII registration required for inspections.'
    end
  end
end
