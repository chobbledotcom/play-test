class SearchController < ApplicationController
  skip_before_action :require_login

  def index
    @federated_sites = Federation.sites(request.host)
  end
end
