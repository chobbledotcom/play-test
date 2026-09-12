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

    BASE_URI = T.let("https://api.bunny.net/mc", String)

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

    # Every application on the account, following the cursor until the final
    # page. The wizard reconciles apps by name, so the lookup must see
    # beyond the first page.
    sig { returns(T::Array[T::Hash[String, T.untyped]]) }
    def applications
      apps = T.cast([], T::Array[T::Hash[String, T.untyped]])
      cursor = ""
      loop do
        path = cursor.empty? ? "/apps" : "/apps?cursor=#{encode(cursor)}"
        page = request(:get, path)
        apps += items(page)
        cursor = page["cursor"].to_s
        break if cursor.empty?
      end
      apps
    end

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
        regionSettings: {
          allowedRegionIds: [region],
          requiredRegionIds: [region]
        },
        runtimeType: runtime_type
      }
      payload[:volumes] = [{name: "storage", size: volume}] if volume
      request(:post, "/apps", payload).fetch("id").to_s
    end

    sig { params(app_id: String).void }
    def deploy(app_id) = request(:post, "/apps/#{app_id}/deploy")

    # Restarts the app's pods so they pick up replaced environment
    # variables - a running container keeps booting with the old set.
    sig { params(app_id: String).void }
    def restart(app_id) = request(:post, "/apps/#{app_id}/restart")

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

      response = Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: true, open_timeout: 10, read_timeout: 30
      ) do |http|
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
      parts = [body&.fetch("title", nil), body&.fetch("detail", nil)]
      parts += validation_messages(body)
      message = parts.compact.join(" - ")
      label = message.empty? ? status.to_s : message
      raise BunnyError.new(
        status,
        I18n.t("magic_container.bunny_client.errors.api_error", label: label)
      )
    end

    # Field-level detail Bunny returns with validation failures. Rejections
    # arrive either as a field=>messages map or as {field, message} rows;
    # without these the raised error hides which field was rejected.
    sig do
      params(body: T.nilable(T::Hash[String, T.untyped]))
        .returns(T::Array[String])
    end
    def validation_messages(body)
      errors = body&.fetch("errors", nil)
      return [] if errors.nil?

      case errors
      when Hash
        errors.map { |field, messages| "#{field}: #{Array(messages).join(", ")}" }
      else
        Array(errors).map do |error|
          field = error.fetch("field", nil)
          message = error.fetch("message", nil)
          field ? "#{field}: #{message}" : message
        end.compact
      end
    end

    sig { params(cursor: String).returns(String) }
    def encode(cursor) = URI.encode_www_form_component(cursor)

    sig { returns(String) }
    attr_reader :access_key

    sig { returns(Transport) }
    attr_reader :transport
  end
end
