# typed: strict
# frozen_string_literal: true

class ThemeConfig < T::Struct
  extend T::Sig

  const :forced_theme, T.nilable(String)
  const :logo_path, String
  const :logo_alt, String
  const :left_logo_path, T.nilable(String)
  const :left_logo_alt, String
  const :right_logo_path, T.nilable(String)
  const :right_logo_alt, String

  sig { params(env: T::Hash[String, T.nilable(String)]).returns(ThemeConfig) }
  def self.from_env(env)
    new(
      forced_theme: env["THEME"],
      logo_path: env.fetch("LOGO_PATH", "logo.svg"),
      logo_alt: env.fetch("LOGO_ALT", "play-test logo"),
      left_logo_path: env["LEFT_LOGO_PATH"],
      left_logo_alt: env.fetch("LEFT_LOGO_ALT", "Logo"),
      right_logo_path: env["RIGHT_LOGO_PATH"],
      right_logo_alt: env.fetch("RIGHT_LOGO_ALT", "Logo")
    )
  end
end
