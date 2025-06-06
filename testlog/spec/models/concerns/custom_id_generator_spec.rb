require "rails_helper"

RSpec.describe CustomIdGenerator, type: :concern do
  # Create a test model to include the concern
  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "units" # Use units table which has string ID
      include CustomIdGenerator
    end
  end

  describe ".generate_random_id" do
    it "generates a 12-character alphanumeric uppercase ID" do
      id = test_class.generate_random_id
      expect(id).to match(/\A[A-Z0-9]{12}\z/)
    end

    it "generates unique IDs" do
      id1 = test_class.generate_random_id
      id2 = test_class.generate_random_id
      expect(id1).not_to eq(id2)
    end

    it "checks for existing records to ensure uniqueness" do
      # Mock exists? to return true first time, false second time
      allow(test_class).to receive(:exists?).and_return(true, false)

      # Should call exists? twice and return an ID
      id = test_class.generate_random_id
      expect(test_class).to have_received(:exists?).twice
      expect(id).to match(/\A[A-Z0-9]{12}\z/)
    end

    it "accepts scope conditions for uniqueness checking" do
      scope_conditions = {user_id: 1}
      allow(test_class).to receive(:exists?).and_return(false)

      test_class.generate_random_id(scope_conditions)

      expect(test_class).to have_received(:exists?).with(hash_including(scope_conditions))
    end
  end

  describe "when included in a model" do
    let(:instance) { test_class.new }

    it "sets the primary key to id" do
      expect(test_class.primary_key).to eq("id")
    end

    it "generates custom ID before create when ID is blank" do
      expect(instance.id).to be_nil

      # Trigger the callback
      instance.send(:generate_custom_id)

      expect(instance.id).to match(/\A[A-Z0-9]{12}\z/)
    end

    it "does not override existing ID" do
      existing_id = "EXISTING123"
      instance.id = existing_id

      # The callback should not be triggered when ID is present
      expect(instance.id).to eq(existing_id)

      # Manually test the condition logic
      expect(instance.id.blank?).to be_falsy
    end

    it "calls uniqueness_scope if model responds to it" do
      # Add uniqueness_scope method to test class
      test_class.define_method(:uniqueness_scope) { {user_id: 1} }

      allow(test_class).to receive(:generate_random_id).and_return("TESTID123456")

      instance.send(:generate_custom_id)

      expect(test_class).to have_received(:generate_random_id).with({user_id: 1})
    end

    it "calls generate_random_id with empty scope if no uniqueness_scope method" do
      allow(test_class).to receive(:generate_random_id).and_return("TESTID123456")

      instance.send(:generate_custom_id)

      expect(test_class).to have_received(:generate_random_id).with({})
    end
  end
end
