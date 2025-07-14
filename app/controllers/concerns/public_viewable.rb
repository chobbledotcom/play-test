module PublicViewable
  extend ActiveSupport::Concern

  included do
    before_action :check_resource_access, only: %i[show]
  end

  def show
    # Implemented by including controllers, but we call render_show_html
    # for HTML format
    if request.format.html?
      render_show_html
    end
  end

  private

  # Access Rules:
  # 1. PDF/JSON/PNG formats: Always allowed for everyone (logged in or not)
  # 2. HTML format:
  #    - Not logged in: Allowed, shows minimal PDF viewer
  #    - Logged in as owner: Allowed, shows full application view
  #    - Logged in as non-owner: Allowed, shows minimal PDF viewer
  # 3. All other actions/formats: Require ownership
  def check_resource_access
    # Rule 1: Always allow PDF/JSON/PNG access for everyone
    return if request.format.pdf? || request.format.json? || request.format.png?

    # Rule 2: Always allow HTML access (show action decides the view)
    return if request.format.html? && action_name == "show"

    # Rule 3: All other cases require ownership
    check_resource_owner
  end

  # To be implemented by including controllers
  def check_resource_owner
    raise NotImplementedError
  end

  # Determine if current user owns the resource
  def owns_resource?
    raise NotImplementedError
  end

  # Render appropriate view for show action
  def render_show_html
    if !logged_in? || !owns_resource?
      # Show minimal PDF viewer for public access or non-owners
      @pdf_title = pdf_filename
      @pdf_url = resource_pdf_url
      render layout: "pdf_viewer"
    end
    # Otherwise render normal view for owners (no explicit render needed)
  end

  # To be implemented by including controllers
  def pdf_filename
    raise NotImplementedError
  end

  def resource_pdf_url
    raise NotImplementedError
  end
end
