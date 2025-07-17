require "rails_helper"

RSpec.describe Federation do
  describe ".sites" do
    context "in local environment" do
      before { allow(Rails.env).to receive(:local?).and_return(true) }

      it "returns all sites when no host is provided" do
        sites = Federation.sites
        expect(sites.length).to eq(3)
        site_names = sites.map { |s| s[:name] }
        expect(site_names).to eq([:current_site, :play_test, :rpii_play_test])
      end

      it "excludes sites matching the current host" do
        sites = Federation.sites("play-test.co.uk")
        expect(sites.length).to eq(2)
        site_names = sites.map { |s| s[:name] }
        expect(site_names).to eq([:current_site, :rpii_play_test])
      end

      it "excludes rpii site when host matches" do
        sites = Federation.sites("rpii.play-test.co.uk")
        expect(sites.length).to eq(2)
        expect(sites.map { |s| s[:name] }).to eq([:current_site, :play_test])
      end
    end

    context "in production environment" do
      before { allow(Rails.env).to receive(:local?).and_return(false) }

      it "returns only current_site" do
        sites = Federation.sites
        expect(sites.length).to eq(1)
        expect(sites.first[:name]).to eq(:current_site)
      end

      it "still returns only current_site when host is provided" do
        sites = Federation.sites("play-test.co.uk")
        expect(sites.length).to eq(1)
        expect(sites.first[:name]).to eq(:current_site)
      end
    end
  end
end
