# typed: strict
# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module MagicContainer
  class BunnyError < StandardError
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :status

    sig { params(status: Integer, detail: String).void }
    def initialize(status, detail)
      @status = status
      super(detail)
    end
  end

  # Client for the Bunny Magic Containers API, documented at
  # https://bunny.net/docs/magic-containers/api-reference
  class BunnyClient
    extend T::Sig

    BASE_URI = "https://api.bunny.net/mc"

    Transport = T.type_alias do
      T.proc.params(
        method: Symbol,
        path: String,
        body: T.nilable(T::Hash[T.untyped, T.untyped])
      ).returns(T::Hash[String, T.untyped])
    end

    sig { params(access_key: String, transport: T.nilable(Transport)).void }
    def initialize(access_key:, transport: nil)
      @access_key = access_key
      @transport = transport || lambda { |method, path, body|
        net_http_request(method, path, body)
      }
    end

    sig { returns(T::Array[T::Hash[String, T.untyped]]) }
    def registries = items(request(:get, "/registries"))

    sig { returns(String) }
    def optimal_region
      region = request(:get, "/regions/optimal").fetch("region")
      T.cast(region, T::Hash[String, T.untyped]).fetch("id")
    end

    sig { returns(T::Array[T::Hash[String, T.untyped]]) }
    def regions = items(request(:get, "/regions"))

    sig do
      params(
        name: String,
        runtime_type: String,
        region: String,
        container: T::Hash[String, T.untyped],
        volume: T.nilable(Integer)
      ).returns(String)
    end
    def create_application(name:, runtime_type:, region:, container:, volume:)
      payload = {
        autoScaling: {min: 1, max: 1},
        containerTemplates: [container],
        name: name,
        regionSettings: {requiredRegionIds: [region]},
        runtimeType: runtime_type
      }
      payload[:volumes] = [{name: "storage", size: volume}] if volume
      request(:post, "/apps", payload).fetch("id").to_s
    end

    sig { params(app_id: String).void }
    def deploy(app_id) = request(:post, "/apps/#{app_id}/deploy")

    sig { params(app_id: String).returns(T::Array[T::Hash[String, T.untyped]]) }
    def endpoints(app_id) = items(request(:get, "/apps/#{app_id}/endpoints"))

    sig do
      params(
        app_id: String,
        container_id: String,
        env: T::Hash[String, String]
      ).void
    end
    def replace_env(app_id, container_id, env)
      request(:put, "/apps/#{app_id}/containers/#{container_id}/env", env)
    end

    private

    sig do
      params(
        method: Symbol,
        path: String,
        body: T.nilable(T::Hash[T.untyped, T.untyped])
      ).returns(T::Hash[String, T.untyped])
    end
    def request(method, path, body = nil)
      result = transport.call(method, path, body)
      T.cast(result, T::Hash[String, T.untyped])
    end

    sig do
      params(
        method: Symbol,
        path: String,
        body: T.nilable(T::Hash[T.untyped, T.untyped])
      ).returns(T::Hash[String, T.untyped])
    end
    def net_http_request(method, path, body = nil)
      uri = URI.parse("#{BASE_URI}#{path}")
      request = build_request(method, uri)
      request["AccessKey"] = access_key
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(body) if body

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
      decoded = decode(response.body)
      raise_error(response.code.to_i, decoded) if response.code.to_i >= 400
      decoded || {}
    end

    sig do
      params(method: Symbol, uri: URI::HTTP).returns(Net::HTTPGenericRequest)
    end
    def build_request(method, uri)
      classes = {
        get: Net::HTTP::Get,
        post: Net::HTTP::Post,
        put: Net::HTTP::Put
      }
      T.unsafe(classes.fetch(method)).new(uri)
    end

    sig do
      params(raw: T.nilable(String))
        .returns(T.nilable(T::Hash[String, T.untyped]))
    end
    def decode(raw)
      return if raw.blank?

      JSON.parse(raw)
    end

    sig do
      params(body: T::Hash[String, T.untyped])
        .returns(T::Array[T::Hash[String, T.untyped]])
    end
    def items(body)
      T.cast(body.fetch("items", []), T::Array[T::Hash[String, T.untyped]])
    end

    sig do
      params(
        status: Integer,
        body: T.nilable(T::Hash[String, T.untyped])
      ).void
    end
    def raise_error(status, body)
      title = body&.fetch("title", nil)
      detail = body&.fetch("detail", nil)
      message = [title, detail].compact.join(" - ")
      label = message.empty? ? status.to_s : message
      raise BunnyError.new(status, "Bunny API error: #{label}")
    end

    attr_reader :access_key
    attr_reader :transport
  end
end
