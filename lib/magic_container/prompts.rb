# typed: strict
# frozen_string_literal: true

require "io/console"

module MagicContainer
  # Terminal prompts for the magic container wizard. Input and output are
  # injectable so the whole question flow can be driven by specs.
  class Prompts
    extend T::Sig

    BOLD = T.let("\e[1m", String)
    BLUE = T.let("\e[34m", String)
    GREEN = T.let("\e[32m", String)
    YELLOW = T.let("\e[33m", String)
    RESET = T.let("\e[0m", String)

    sig do
      params(
        input: T.any(IO, StringIO),
        output: T.any(IO, StringIO)
      ).void
    end
    def initialize(input: $stdin, output: $stdout)
      @input = input
      @output = output
    end

    sig { params(label: String).void }
    def banner(label)
      output.puts
      output.puts "#{BOLD}#{BLUE}== #{label} ==#{RESET}"
    end

    # A nil default makes the question required; a blank default ("")
    # makes it optional, returning the empty string.
    sig { params(label: String, default: T.nilable(String)).returns(String) }
    def ask(label, default: nil)
      loop do
        suffix = default.nil? ? "" : " [#{default}]"
        answer = question("#{label}#{suffix}")
        return default if answer.empty? && !default.nil?
        return answer unless answer.empty?

        output.puts "#{YELLOW}A value is required.#{RESET}"
      end
    end

    sig { params(label: String, required: T::Boolean).returns(String) }
    def secret(label, required: false)
      suffix = required ? "" : " (blank to skip)"
      answer = hidden_question("#{label}#{suffix}")
      while answer.empty? && required
        output.puts "#{YELLOW}A value is required.#{RESET}"
        answer = hidden_question("#{label}#{suffix}")
      end
      output.puts "(hidden input)"
      answer
    end

    sig do
      params(
        label: String,
        choices: T::Array[[String, String]]
      ).returns(String)
    end
    def select(label, choices)
      output.puts "#{BOLD}#{label}#{RESET}"
      choices.each_with_index do |(name, _value), index|
        output.puts "  #{index + 1}. #{name}"
      end

      choice = ask("Number", default: "1")
      number = Integer(choice, 10, exception: false)
      if number
        index = number - 1
        within_range = index.between?(0, choices.length - 1)
        return T.must(choices[index]).last if within_range
      end

      output.puts "#{YELLOW}Not a valid choice.#{RESET}"
      select(label, choices)
    end

    sig { params(label: String, default: T::Boolean).returns(T::Boolean) }
    def confirm(label, default: true)
      hint = default ? "Y/n" : "y/N"
      answer = question("#{label} [#{hint}]").downcase
      return default if answer.empty?

      %w[y yes].include?(answer)
    end

    sig { params(label: String).void }
    def note(label)
      output.puts "#{GREEN}#{label}#{RESET}"
    end

    private

    # Closed input cannot answer a required question, so abort instead of
    # looping forever. This happens when the user presses Ctrl-D or when
    # piped input ends before all questions are answered.
    sig { returns(String) }
    def read_line
      line = input.gets
      raise EOFError, "Input closed before the question was answered" if line.nil?

      line.chomp
    end

    sig { params(label: String).returns(String) }
    def question(label)
      output.print "#{BOLD}#{label}:#{RESET} "
      output.flush
      read_line
    end

    sig { params(label: String).returns(String) }
    def hidden_question(label)
      output.print "#{BOLD}#{label}:#{RESET} "
      output.flush
      return read_line unless input.respond_to?(:noecho)

      input.noecho { read_line }
    end

    sig { returns(T.any(IO, StringIO)) }
    attr_reader :input

    sig { returns(T.any(IO, StringIO)) }
    attr_reader :output
  end
end
