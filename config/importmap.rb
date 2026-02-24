# typed: false

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "comment_toggles", to: "comment_toggles.js"
pin "na_toggles", to: "na_toggles.js"
pin "na_number_toggles", to: "na_number_toggles.js"
pin "details_links"
pin "dirty_forms"
pin "share_buttons"
pin "safety_standards_tabs"
pin "guides_slider"
pin "search"
pin "image_resize"
pin "webauthn_utils", to: "webauthn_utils.js"
pin "passkey_registration", to: "passkey_registration.js"
pin "passkey_login", to: "passkey_login.js"
pin "text_replacement_form"

# external libs
pin "highlight.js", to: "highlight.js"
