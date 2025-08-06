require "rails_helper"

RSpec.feature "Admin Files", type: :feature do
  let(:admin_user) { create(:user, :admin) }

  before do
    sign_in(admin_user)
  end

  scenario "displays files list" do
    visit admin_path
    click_link I18n.t("navigation.files")

    expect(page).to have_content(I18n.t("admin.files.title"))
    # When no files exist, should show no files message instead of table
    expect(page).to have_content(I18n.t("admin.files.no_files"))
  end

  scenario "shows no files message when empty" do
    visit admin_files_path

    expect(page).to have_content(I18n.t("admin.files.no_files"))
  end

  context "with attached files" do
    let(:inspection) { create(:inspection) }
    let(:unit) { create(:unit) }

    before do
      # Create some test attachments
      inspection.photo_1.attach(
        io: StringIO.new("test image content"),
        filename: "inspection_photo.jpg",
        content_type: "image/jpeg"
      )

      unit.photo.attach(
        io: StringIO.new("test image"),
        filename: "unit_photo.jpg",
        content_type: "image/jpeg"
      )
    end

    scenario "displays files in table with proper information" do
      visit admin_files_path

      within "table" do
        expect(page).to have_content("inspection_photo.jpg")
        expect(page).to have_content("unit_photo.jpg")

        # Check for links to attached records
        expect(page).to have_link(
          I18n.t("admin.files.attached_to.inspection", id: inspection.id),
          href: inspection_path(inspection)
        )
        expect(page).to have_link(
          I18n.t("admin.files.attached_to.unit", serial: unit.serial),
          href: unit_path(unit)
        )
      end
    end

    scenario "provides download links for files" do
      visit admin_files_path

      expect(page).to have_link("inspection_photo.jpg")
      expect(page).to have_link("unit_photo.jpg")
    end
  end
end
