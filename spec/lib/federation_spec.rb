# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Federation do
  describe ".sites" do
    context "in local environment" do
      before { allow(Rails.env).to receive(:local?).and_return(true) }

      it "returns all sites when no host is provided" do
        sites = Federation.sites
        expect(sites.length).to eq(3)
        site_names = sites.map { |s| s[:name] }
        expect(site_names).to eq(%i[current_site play_test rpii_play_test])
      end

      it "excludes sites matching the current host" do
        sites = Federation.sites("play-test.co.uk")
        expect(sites.length).to eq(2)
        site_names = sites.map { |s| s[:name] }
        expect(site_names).to eq(%i[current_site rpii_play_test])
      end

      it "excludes rpii site when host matches" do
        sites = Federation.sites("rpii.play-test.co.uk")
        expect(sites.length).to eq(2)
        expect(sites.map { |s| s[:name] }).to eq(%i[current_site play_test])
      end
    end
  end
end
