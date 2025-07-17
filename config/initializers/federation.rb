# Federation configuration for searching across multiple sites
# Each site in the array represents a federated instance that can be searched
# The current site uses an empty host to indicate local searches

# Site names are defined as symbols to be looked up in I18n translations
# under the search.sites namespace
module Federation
  def self.sites(current_host = nil, current_user = nil)
    all_sites = [{name: :current_site, host: ""}]

    if Rails.env.local? || current_user&.admin?
      all_sites.concat([
        {name: :play_test, host: "play-test.co.uk"},
        {name: :rpii_play_test, host: "rpii.play-test.co.uk"}
      ])
    end

    return all_sites unless current_host

    all_sites.reject { |site| site[:host] == current_host }
  end
end
