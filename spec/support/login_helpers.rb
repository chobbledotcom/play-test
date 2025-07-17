module LoginHelpers
  include FormHelpers

  def login_as(user)
    post "/login", params: { session: { email: user.email, password: user.password } }
  end

  def login_user_via_form(user)
    visit login_path
    fill_in_form(:session_new, :email, user.email)
    fill_in_form(:session_new, :password, user.password)
    submit_form(:session_new)
  end

  def sign_in(user)
    visit login_path
    fill_in_form(:session_new, :email, user.email)
    fill_in_form(:session_new, :password, user.password)
    submit_form(:session_new)
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

  # For feature tests - clicks the logout button
  def logout
    click_button I18n.t("sessions.buttons.log_out")
  end

  # For request tests - sends DELETE request
  def logout_user
    delete "/logout"
  end
end

RSpec.configure do |config|
  config.include LoginHelpers, type: :request
  config.include LoginHelpers, type: :feature
  config.include LoginHelpers, type: :view
end
