# typed: false

require "rails_helper"

RSpec.describe "Pages", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:page) { create(:page) }

  describe "GET /pages (index)" do
    context "as admin" do
      before { login_as(admin_user) }

      it "returns http success" do
        get pages_path
        expect(response).to have_http_status(:success)
      end

      it "displays all pages" do
        create(:page, slug: "page1", link_title: "Page 1")
        create(:page, slug: "page2", link_title: "Page 2")

        get pages_path
        expect(response.body).to include("Page 1")
        expect(response.body).to include("Page 2")
      end
    end

    context "as regular user" do
      before { login_as(regular_user) }

      it "redirects to root" do
        get pages_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /pages/:slug (show)" do
    let!(:test_page) do
      create(:page, slug: "test", content: "<h1>Test Page</h1>")
    end

    context "without authentication" do
      it "returns http success" do
        get page_by_slug_path("test")
        expect(response).to have_http_status(:success)
      end

      it "displays the page content" do
        get page_by_slug_path("test")
        expect(response.body).to include("<h1>Test Page</h1>")
      end
    end

    context "with authentication" do
      before { login_as(regular_user) }

      it "returns http success" do
        get page_by_slug_path("test")
        expect(response).to have_http_status(:success)
      end
    end

    it "returns 404 for non-existent page" do
      get page_by_slug_path("non-existent")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /pages/new" do
    context "as admin" do
      before { login_as(admin_user) }

      it "returns http success" do
        get new_page_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as regular user" do
      before { login_as(regular_user) }

      it "redirects to root" do
        get new_page_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /pages" do
    context "as admin" do
      before { login_as(admin_user) }

      context "with valid params" do
        let(:valid_params) do
          {
            page: {
              slug: "new-page",
              link_title: "New Page",
              meta_title: "New Page Title",
              meta_description: "Description",
              content: "<h1>New Content</h1>"
            }
          }
        end

        it "creates a new page" do
          expect {
            post pages_path, params: valid_params
          }.to change(Page, :count).by(1)
        end

        it "redirects to the created page" do
          post pages_path, params: valid_params
          page = Page.find_by(slug: "new-page")
          expect(response).to redirect_to(page_path(page))
        end
      end

      context "with invalid params" do
        let(:invalid_params) do
          {
            page: {
              slug: "",
              link_title: "",
              content: ""
            }
          }
        end

        it "does not create a new page" do
          expect {
            post pages_path, params: invalid_params
          }.not_to change(Page, :count)
        end

        it "returns unprocessable entity" do
          post pages_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "GET /pages/:id/edit" do
    context "as admin" do
      before { login_as(admin_user) }

      it "returns http success" do
        get edit_page_path(page)
        expect(response).to have_http_status(:success)
      end
    end

    context "as regular user" do
      before { login_as(regular_user) }

      it "redirects to root" do
        get edit_page_path(page)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /pages/:id" do
    context "as admin" do
      before { login_as(admin_user) }

      context "with valid params" do
        it "updates the page" do
          patch page_path(page), params: {
            page: {link_title: "Updated Title"}
          }
          expect(page.reload.link_title).to eq("Updated Title")
        end

        it "redirects to the updated page" do
          patch page_path(page), params: {
            page: {link_title: "Updated Title"}
          }
          expect(response).to redirect_to(page_path(page))
        end
      end

      context "with invalid params" do
        it "returns unprocessable entity" do
          patch page_path(page), params: {
            page: {slug: ""}
          }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "DELETE /pages/:id" do
    context "as admin" do
      before { login_as(admin_user) }

      it "deletes the page" do
        page_to_delete = create(:page)
        expect {
          delete page_path(page_to_delete)
        }.to change(Page, :count).by(-1)
      end

      it "redirects to pages index" do
        delete page_path(page)
        expect(response).to redirect_to(pages_path)
      end
    end

    context "as regular user" do
      before { login_as(regular_user) }

      it "redirects to root" do
        delete page_path(page)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET / (root path)" do
    let!(:homepage) { create(:page, slug: "/", content: "<h1>Homepage</h1>") }

    context "without authentication" do
      it "returns http success" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "displays the homepage content" do
        get root_path
        expect(response.body).to include("<h1>Homepage</h1>")
      end
    end
  end
end
