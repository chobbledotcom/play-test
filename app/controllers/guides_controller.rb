class GuidesController < ApplicationController
  skip_before_action :require_login

  def index
    @guides = collect_guides
  end

  def show
    guide_path = params[:path]
    metadata_file = guide_screenshots_root.join(guide_path, "metadata.json")
    
    if metadata_file.exist?
      @guide_data = JSON.parse(metadata_file.read)
      @guide_path = guide_path
      @guide_title = humanize_guide_title(guide_path)
    else
      redirect_to guides_path, alert: I18n.t("guides.messages.not_found")
    end
  end

  private

  def guide_screenshots_root
    Rails.root.join("public", "guide_screenshots")
  end

  def collect_guides
    guides = []
    
    # Find all metadata.json files
    Dir.glob(guide_screenshots_root.join("**", "metadata.json")).each do |metadata_path|
      relative_path = Pathname.new(metadata_path).relative_path_from(guide_screenshots_root).dirname.to_s
      metadata = JSON.parse(File.read(metadata_path))
      
      guides << {
        path: relative_path,
        title: humanize_guide_title(relative_path),
        screenshot_count: metadata["screenshots"].size,
        updated_at: metadata["updated_at"],
        first_screenshot: metadata["screenshots"].first
      }
    end
    
    guides.sort_by { |g| g[:title] }
  end

  def humanize_guide_title(path)
    # Convert spec/features/inspections/inspection_creation_workflow_spec to "Inspection Creation Workflow"
    path.split("/").last.gsub(/_spec$/, "").humanize
  end
end