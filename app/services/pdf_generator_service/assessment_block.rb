# typed: false

class PdfGeneratorService
  class AssessmentBlock
    attr_reader :type, :pass_fail, :name, :value, :comment

    def initialize(type:, pass_fail: nil, name: nil, value: nil, comment: nil)
      @type = type
      @pass_fail = pass_fail
      @name = name
      @value = value
      @comment = comment
    end

    def header?
      type == :header
    end

    def value?
      type == :value
    end

    def comment?
      type == :comment
    end
  end
end
