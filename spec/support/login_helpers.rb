module LoginHelpers
  def login_as(user)
    post "/login", params: {session: {email: user.email, password: user.password}}
  end

  def login_user_via_form(user)
    visit login_path
    fill_in I18n.t("forms.session_new.fields.email"), with: user.email
    fill_in I18n.t("forms.session_new.fields.password"), with: user.password
    click_button I18n.t("forms.session_new.submit")
  end

  def sign_in(user)
    visit login_path
    fill_in I18n.t("forms.session_new.fields.email"), with: user.email
    fill_in I18n.t("forms.session_new.fields.password"), with: user.password
    click_button I18n.t("forms.session_new.submit")
  end

  def create_and_login_user(attributes = {})
    user = create(:user, attributes)
    login_as(user)
    user
  end

  def create_and_login_admin(attributes = {})
    admin = create(:user, :admin, attributes)
    login_as(admin)
    admin
  end
end

RSpec.configure do |config|
  config.include LoginHelpers, type: :request
  config.include LoginHelpers, type: :feature
  config.include LoginHelpers, type: :view
end
