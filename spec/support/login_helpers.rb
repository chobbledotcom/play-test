# typed: strict
# frozen_string_literal: true

module LoginHelpers
  extend T::Sig
  include FormHelpers

  sig { params(user: User).void }
  def login_as(user)
    post "/login", params: {session: {email: user.email, password: user.password}}
  end

  sig { params(user: User).void }
  def login_user_via_form(user)
    visit login_path
    fill_in_form :session_new, :email, user.email
    fill_in_form :session_new, :password, user.password
    submit_form :session_new
  end

  sig { params(user: User).void }
  def sign_in(user)
    visit login_path
    fill_in_form :session_new, :email, user.email
    fill_in_form :session_new, :password, user.password
    submit_form :session_new
  end

  sig { params(attributes: T::Hash[Symbol, T.untyped]).returns User }
  def create_and_login_user(attributes = {})
    user = create :user, attributes
    login_as user
    user
  end

  sig { params(attributes: T::Hash[Symbol, T.untyped]).returns User }
  def create_and_login_admin(attributes = {})
    admin = create :user, :admin, attributes
    login_as admin
    admin
  end

  # For feature tests - clicks the logout button
  sig { void }
  def logout
    click_button I18n.t("sessions.buttons.log_out")
  end

  # For request tests - sends DELETE request
  sig { void }
  def logout_user
    delete "/logout"
  end
end

RSpec.configure do |config|
  config.include LoginHelpers, type: :request
  config.include LoginHelpers, type: :feature
  config.include LoginHelpers, type: :view
end
