# Federation configuration for searching across multiple sites
# Each site in the array represents a federated instance that can be searched
# The current site uses an empty URL to indicate local searches

# Site names are defined as symbols to be looked up in I18n translations
# under the search.sites namespace
FEDERATED_SITES = [
  {name: :current_site, url: ""}, # Empty URL for current/local site
  {name: :play_test, url: "https://play-test.co.uk"},
  {name: :rpii_play_test, url: "https://rpii.play-test.co.uk"}
].freeze
