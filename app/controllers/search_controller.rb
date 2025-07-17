class SearchController < ApplicationController
  skip_before_action :require_login

  def index
    @federated_sites = FEDERATED_SITES
  end
end
