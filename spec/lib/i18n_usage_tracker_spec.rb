require "rails_helper"

RSpec.describe I18nUsageTracker do
  # Clean up state before each test
  before do
    described_class.reset!
  end

  after do
    described_class.reset!
  end

  describe ".reset!" do
    it "clears used keys and disables tracking" do
      described_class.tracking_enabled = true
      described_class.instance_variable_set(:@used_keys, Set.new(["test.key"]))

      described_class.reset!

      expect(described_class.used_keys).to be_empty
      expect(described_class.tracking_enabled).to be false
    end
  end

  describe ".tracking_enabled" do
    it "can be set and retrieved" do
      expect(described_class.tracking_enabled).to be false

      described_class.tracking_enabled = true
      expect(described_class.tracking_enabled).to be true
    end
  end

  describe ".track_key" do
    context "when tracking is disabled" do
      before { described_class.tracking_enabled = false }

      it "does not track keys" do
        described_class.track_key("test.key")
        expect(described_class.used_keys).to be_empty
      end
    end

    context "when tracking is enabled" do
      before { described_class.tracking_enabled = true }

      it "tracks simple keys" do
        described_class.track_key("test_key")
        expect(described_class.used_keys).to include("test_key")
      end

      it "tracks symbol keys by converting to string" do
        described_class.track_key(:test_key)
        expect(described_class.used_keys).to include("test_key")
      end

      it "tracks nested keys and their parents" do
        described_class.track_key("users.messages.created")

        expect(described_class.used_keys).to include("users.messages.created")
        expect(described_class.used_keys).to include("users.messages")
        expect(described_class.used_keys).to include("users")
      end

      it "handles nil keys gracefully" do
        expect { described_class.track_key(nil) }.not_to raise_error
        expect(described_class.used_keys).to be_empty
      end

      it "tracks empty string keys" do
        described_class.track_key("")
        expect(described_class.used_keys).to include("")
      end

      it "skips Rails internal keys" do
        rails_keys = [
          "errors.messages.blank",
          "activerecord.errors.messages.blank",
          "activemodel.errors.messages.invalid",
          "helpers.submit.create",
          "number.currency.format.unit",
          "date.formats.default",
          "time.formats.short",
          "support.array.last_word_connector"
        ]

        rails_keys.each do |key|
          described_class.track_key(key)
        end

        expect(described_class.used_keys).to be_empty
      end

      context "with scope option" do
        it "tracks scoped keys" do
          described_class.track_key("created", scope: "users.messages")

          expect(described_class.used_keys).to include("created")
          expect(described_class.used_keys).to include("users.messages.created")
          expect(described_class.used_keys).to include("users.messages")
          expect(described_class.used_keys).to include("users")
        end

        it "handles array scope" do
          described_class.track_key("created", scope: ["users", "messages"])

          expect(described_class.used_keys).to include("users.messages.created")
          expect(described_class.used_keys).to include("users.messages")
          expect(described_class.used_keys).to include("users")
        end

        it "handles symbol scope" do
          described_class.track_key("created", scope: :users)

          expect(described_class.used_keys).to include("users.created")
          expect(described_class.used_keys).to include("users")
        end
      end
    end
  end

  describe ".all_locale_keys" do
    it "returns a set of all available locale keys" do
      keys = described_class.all_locale_keys

      expect(keys).to be_a(Set)
      expect(keys).not_to be_empty
    end

    it "includes keys from all locale files" do
      keys = described_class.all_locale_keys

      # Check for some keys we know exist in the app
      expect(keys).to include("users")
      expect(keys).to include("inspections")
      expect(keys).to include("shared")
    end

    it "caches the result" do
      # First call loads from files
      first_call = described_class.all_locale_keys

      # Second call should return cached version
      expect(described_class).not_to receive(:extract_keys_from_hash)
      second_call = described_class.all_locale_keys

      expect(first_call).to eq(second_call)
    end
  end

  describe ".unused_keys" do
    before { described_class.tracking_enabled = true }

    it "returns keys that haven't been tracked" do
      all_keys = described_class.all_locale_keys

      # Track some keys
      described_class.track_key("users.edit.title")
      described_class.track_key("shared.save")

      unused = described_class.unused_keys

      expect(unused).to be_a(Set)
      expect(unused).not_to include("users.edit.title")
      expect(unused).not_to include("users.edit")
      expect(unused).not_to include("users")
      expect(unused).not_to include("shared.save")
      expect(unused).not_to include("shared")

      # Should include keys that weren't tracked
      expect(unused.size).to be < all_keys.size
    end
  end

  describe ".usage_report" do
    before { described_class.tracking_enabled = true }

    it "returns a comprehensive usage report" do
      # Track some keys
      described_class.track_key("users.edit.title")
      described_class.track_key("shared.save")

      report = described_class.usage_report

      expect(report).to include(:total_keys, :used_keys, :unused_keys, :usage_percentage, :unused_key_list)
      expect(report[:total_keys]).to be > 0
      expect(report[:used_keys]).to be > 0
      expect(report[:unused_keys]).to be >= 0
      expect(report[:usage_percentage]).to be_between(0, 100)
      expect(report[:unused_key_list]).to be_an(Array)
    end

    it "calculates usage percentage correctly" do
      # Mock all_locale_keys to have a known set
      known_keys = Set.new(["users", "users.edit", "users.edit.title", "shared", "shared.save"])
      allow(described_class).to receive(:all_locale_keys).and_return(known_keys)

      # Track some keys (this will also track parent keys)
      described_class.track_key("users.edit.title")  # tracks users, users.edit, users.edit.title
      described_class.track_key("shared.save")       # tracks shared, shared.save

      report = described_class.usage_report

      expect(report[:total_keys]).to eq(5)
      expect(report[:used_keys]).to eq(5)  # All keys tracked
      expect(report[:unused_keys]).to eq(0)
      expect(report[:usage_percentage]).to eq(100.0)
    end
  end

  describe "private .extract_keys_from_hash" do
    it "extracts all keys from nested hash" do
      hash = {
        "users" => {
          "edit" => {
            "title" => "Edit User"
          },
          "index" => {
            "title" => "All Users"
          }
        },
        "shared" => {
          "save" => "Save"
        }
      }

      keys = Set.new
      described_class.send(:extract_keys_from_hash, hash, [], keys)

      expected_keys = [
        "users",
        "users.edit",
        "users.edit.title",
        "users.index",
        "users.index.title",
        "shared",
        "shared.save"
      ]

      expected_keys.each do |key|
        expect(keys).to include(key)
      end
    end

    it "handles simple values" do
      hash = {"simple" => "value"}
      keys = Set.new

      described_class.send(:extract_keys_from_hash, hash, [], keys)

      expect(keys).to include("simple")
    end
  end
end

# Test I18n monkey patching
RSpec.describe "I18n monkey patch" do
  before do
    I18nUsageTracker.reset!
    I18nUsageTracker.tracking_enabled = true
  end

  after do
    I18nUsageTracker.reset!
  end

  describe "I18n.t" do
    it "tracks keys when called" do
      # Use a key that exists in the app
      I18n.t("hello")

      expect(I18nUsageTracker.used_keys).to include("hello")
    end

    it "works with scope option" do
      I18n.t("save", scope: "shared.actions")

      expect(I18nUsageTracker.used_keys).to include("save")
      expect(I18nUsageTracker.used_keys).to include("shared.actions.save")
      expect(I18nUsageTracker.used_keys).to include("shared.actions")
      expect(I18nUsageTracker.used_keys).to include("shared")
    end

    it "does not track when tracking is disabled" do
      I18nUsageTracker.tracking_enabled = false

      I18n.t("hello")

      expect(I18nUsageTracker.used_keys).to be_empty
    end
  end

  describe "I18n.translate" do
    it "tracks keys when called" do
      I18n.translate("hello")

      expect(I18nUsageTracker.used_keys).to include("hello")
    end
  end
end
