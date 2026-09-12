# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe MagicContainer::BunnyClient do
  subject(:client) { described_class.new(access_key: "bunny-key", transport:) }

  let(:calls) { [] }
  let(:responses) do
    {
      "/apps" => {"id" => 42},
      "/apps/app-1/deploy" => {},
      "/apps/app-1/restart" => {},
      "/apps/app-1/endpoints" => {"items" => [{"publicHost" => "mc-1.bunny.run"}]},
      "/apps/app-1/containers/c-9/env" => {},
      "/registries" => {"items" => [{"displayName" => "Docker Hub", "hostName" => "docker.io", "id" => 7}]},
      "/regions/optimal" => {"region" => {"id" => "LDN"}},
      "/regions" => {"items" => [{"id" => "LDN", "name" => "London", "hasCapacity" => true}]}
    }
  end
  let(:transport) do
    lambda { |method, path, body|
      calls << {method: method, path: path, body: body}
      responses.fetch(path)
    }
  end

  it "lists registries" do
    expect(client.registries).to eq([{"displayName" => "Docker Hub", "hostName" => "docker.io", "id" => 7}])
    expect(calls.first[:path]).to eq("/registries")
  end

  it "fetches a single application's full configuration" do
    responses["/apps/app-2"] = {
      "id" => "app-2",
      "containerTemplates" => [{"imageName" => "app"}]
    }

    expect(client.application("app-2")).to include("id" => "app-2")
    expect(calls.first[:path]).to eq("/apps/app-2")
  end

  it "lists every application across cursor pages" do
    pages = {
      "/apps" => {
        "items" => [{"id" => 42, "name" => "play-test"}],
        "cursor" => "next page"
      },
      "/apps?cursor=next+page" => {"items" => [{"id" => 43, "name" => "another"}]}
    }
    paginated = lambda { |method, path, body|
      calls << {method: method, path: path, body: body}
      pages.fetch(path)
    }
    paginated_client = described_class.new(access_key: "bunny-key", transport: paginated)

    expect(paginated_client.applications).to eq(
      [{"id" => 42, "name" => "play-test"}, {"id" => 43, "name" => "another"}]
    )
    expect(calls.pluck(:path)).to eq(["/apps", "/apps?cursor=next+page"])
  end

  it "returns the optimal region id" do
    expect(client.optimal_region).to eq("LDN")
  end

  it "lists regions" do
    expect(client.regions.first).to include("id" => "LDN", "hasCapacity" => true)
  end

  it "posts the full application payload and returns the app id" do
    container = {name: "app"}
    app_id = client.create_application(
      container: container,
      name: "play-test",
      region: "LDN",
      runtime_type: "shared",
      volume: 5
    )

    expect(app_id).to eq("42")
    call = calls.first
    expect(call[:method]).to eq(:post)
    expect(call[:path]).to eq("/apps")
    expect(call[:body]).to eq(
      autoScaling: {min: 1, max: 1},
      containerTemplates: [{name: "app"}],
      name: "play-test",
      regionSettings: {allowedRegionIds: ["LDN"], requiredRegionIds: ["LDN"]},
      runtimeType: "shared",
      volumes: [{name: "storage", size: 5}]
    )
  end

  it "omits the volume when none is given" do
    client.create_application(
      container: {name: "app"},
      name: "play-test",
      region: "LDN",
      runtime_type: "shared",
      volume: nil
    )

    expect(calls.first[:body]).not_to have_key(:volumes)
  end

  it "deploys the application" do
    client.deploy("app-1")

    expect(calls.first).to include(method: :post, path: "/apps/app-1/deploy")
  end

  it "restarts the application" do
    client.restart("app-1")

    expect(calls.first).to include(method: :post, path: "/apps/app-1/restart")
  end

  it "lists application endpoints" do
    expect(client.endpoints("app-1")).to eq([{"publicHost" => "mc-1.bunny.run"}])
  end

  it "replaces container environment variables" do
    client.replace_env("app-1", "c-9", {"BASE_URL" => "https://mc-1.bunny.run"})

    call = calls.first
    expect(call[:method]).to eq(:put)
    expect(call[:path]).to eq("/apps/app-1/containers/c-9/env")
    expect(call[:body]).to eq({"BASE_URL" => "https://mc-1.bunny.run"})
  end

  context "when the API rejects the request" do
    subject(:strict_client) { described_class.new(access_key: "bunny-key") }

    it "raises BunnyError with the API detail" do
      response = instance_double(
        Net::HTTPNotFound,
        code: "404",
        body: {"title" => "Not Found", "detail" => "Application missing"}.to_json
      )
      allow(Net::HTTP).to receive(:start).and_return(response)

      expect { strict_client.registries }
        .to raise_error(MagicContainer::BunnyError, "Bunny API error: Not Found - Application missing")
    end

    it "raises BunnyError with field-level validation rows" do
      body = {
        "title" => "Validation Error",
        "detail" => "One or more validation errors occurred.",
        "errors" => [
          {"field" => "RegionSettings", "message" => "The allowedRegionIds field is required."}
        ]
      }
      response = instance_double(Net::HTTPBadRequest, code: "400", body: body.to_json)
      allow(Net::HTTP).to receive(:start).and_return(response)

      expect { strict_client.registries }.to raise_error(MagicContainer::BunnyError) do |error|
        expect(error.message).to eq(
          "Bunny API error: Validation Error - One or more validation errors" \
            " occurred. - RegionSettings: The allowedRegionIds field is required."
        )
      end
    end

    it "raises BunnyError with field-level validation maps" do
      body = {
        "title" => "Validation Error",
        "detail" => "One or more validation errors occurred.",
        "errors" => {"RegionSettings" => ["The allowedRegionIds field is required."]}
      }
      response = instance_double(Net::HTTPBadRequest, code: "400", body: body.to_json)
      allow(Net::HTTP).to receive(:start).and_return(response)

      expect { strict_client.registries }.to raise_error(MagicContainer::BunnyError) do |error|
        expect(error.message).to eq(
          "Bunny API error: Validation Error - One or more validation errors" \
            " occurred. - RegionSettings: The allowedRegionIds field is required."
        )
      end
    end

    it "exposes the HTTP status" do
      response = instance_double(Net::HTTPNotFound, code: "404", body: "")
      allow(Net::HTTP).to receive(:start).and_return(response)

      expect { strict_client.registries }.to raise_error do |error|
        expect(error.status).to eq(404)
      end
    end
  end
end
