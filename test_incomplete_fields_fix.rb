# Test script to verify incomplete_fields_grouped is accessible

# Mock Rails-like environment
module ActiveSupport
  module Concern
    def self.extended(base)
      base.instance_variable_set(:@_dependencies, [])
    end

    def included(base = nil, &block)
      if base.nil?
        if instance_variable_defined?(:@_included_block)
          if @_included_block.source_location != block.source_location
            raise "Cannot define multiple included blocks"
          end
        else
          @_included_block = block
        end
      else
        super
      end
    end

    def class_methods(&class_methods_module_definition)
      mod = const_defined?(:ClassMethods, false) ?
        const_get(:ClassMethods) :
        const_set(:ClassMethods, Module.new)

      mod.module_eval(&class_methods_module_definition)
    end
  end
end

class Set
  def initialize(enum = nil)
    @hash = {}
    merge(enum) if enum
  end

  def merge(enum)
    enum.each { |o| add(o) }
    self
  end

  def add(o)
    @hash[o] = true
    self
  end

  def include?(o)
    @hash.include?(o)
  end
end

module FieldUtils
  def self.strip_field_suffix(field)
    field.to_s.sub(/_pass$|_comment$/, "")
  end

  def self.get_composite_fields(field, partial)
    case partial
    when "decimal_comment"
      [:"#{field}", :"#{field}_comment"]
    when "pass_fail_comment"
      [:"#{field}_pass", :"#{field}_comment"]
    else
      [:"#{field}"]
    end
  end
end

# Load the concern
require_relative 'app/models/concerns/assessment_completion'

# Create a test class
class TestAssessment
  include AssessmentCompletion

  attr_accessor :attributes

  def initialize
    @attributes = {
      "id" => 1,
      "inspection_id" => 1,
      "created_at" => Time.now,
      "updated_at" => Time.now,
      "field1" => nil,
      "field1_pass" => nil,
      "field2" => "value",
      "field2_pass" => "pass",
      "field3" => nil,
      "field3_pass" => "na"
    }
  end

  def self.form_fields
    [
      {
        fields: [
          { field: :field1, partial: "pass_fail_comment" },
          { field: :field2, partial: "pass_fail_comment" },
          { field: :field3, partial: "pass_fail_comment" }
        ]
      }
    ]
  end

  def send(method)
    @attributes[method.to_s]
  end

  def respond_to?(method)
    @attributes.key?(method.to_s)
  end
end

# Test the methods
assessment = TestAssessment.new

puts "Testing incomplete_fields method..."
incomplete = assessment.incomplete_fields
puts "Incomplete fields: #{incomplete.inspect}"
puts "Expected: [:field1, :field1_pass] (field3 should be excluded due to NA)"
puts ""

puts "Testing incomplete_fields_grouped method (should be public now)..."
begin
  grouped = assessment.incomplete_fields_grouped
  puts "Grouped fields: #{grouped.inspect}"
  puts "Success! Method is public and callable."
rescue NoMethodError => e
  puts "ERROR: #{e.message}"
  puts "The method is still private!"
end