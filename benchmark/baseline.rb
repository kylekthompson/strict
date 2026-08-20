# frozen_string_literal: true

require "strict"

module StrictBenchmark
  BenchmarkCase = Data.define(:name, :operation)

  ITERATIONS = Integer(ENV.fetch("ITERATIONS", "100000"), 10)
  WARMUP_ITERATIONS = Integer(ENV.fetch("WARMUP_ITERATIONS", "20000"), 10)
  SAMPLES = Integer(ENV.fetch("SAMPLES", "5"), 10)
  FORMAT = ENV.fetch("FORMAT", "text")
  FORMATS = %w[markdown text].freeze

  class Value
    include Strict::Value

    attributes do
      id Integer
      name String
      active Boolean()
    end
  end

  class VerifiedMethod
    include Strict::Method

    sig do
      value Integer
      returns Integer
    end
    def call(value:) = value
  end

  class Interface
    include Strict::Interface

    expose(:call) do
      value Integer
      returns Integer
    end
  end

  class Implementation
    def call(value:) = value
  end

  class Formatter
    def initialize(output_format)
      @output_format = output_format
    end

    def print_header
      puts markdown? ? markdown_header : text_header
    end

    def print_result(name:, nanoseconds:, allocations:)
      result = if markdown?
                 markdown_result(name:, nanoseconds:, allocations:)
               else
                 text_result(name:, nanoseconds:, allocations:)
               end
      puts result
    end

    private

    attr_reader :output_format

    def markdown? = output_format == "markdown"

    def markdown_header
      <<~MARKDOWN.chomp
        ### Strict benchmark

        `Ruby #{RUBY_VERSION} (#{RUBY_ENGINE})`

        Iterations: #{ITERATIONS}; warmup: #{WARMUP_ITERATIONS}; samples: #{SAMPLES}

        | Operation | Median ns/op | Allocations/op |
        | --- | ---: | ---: |
      MARKDOWN
    end

    def text_header
      <<~TEXT.chomp
        Ruby #{RUBY_VERSION} (#{RUBY_ENGINE})
        Iterations: #{ITERATIONS}; warmup: #{WARMUP_ITERATIONS}; samples: #{SAMPLES}
        Operation                      median ns/op     allocations/op
      TEXT
    end

    def markdown_result(name:, nanoseconds:, allocations:)
      format("| %<name>s | %<nanoseconds>.1f | %<allocations>.3f |", name:, nanoseconds:, allocations:)
    end

    def text_result(name:, nanoseconds:, allocations:)
      format("%<name>-24s %<nanoseconds>18.1f %<allocations>18.3f", name:, nanoseconds:, allocations:)
    end
  end

  class << self
    def run
      validate_settings!
      benchmark_cases = build_cases
      warm_up(benchmark_cases)
      formatter = Formatter.new(FORMAT)

      formatter.print_header
      benchmark_cases.each { |benchmark_case| print_result(formatter, benchmark_case) }
    end

    private

    def print_result(formatter, benchmark_case)
      nanoseconds = median(measure_times(benchmark_case.operation)) * 1_000_000_000 / ITERATIONS
      allocations = measure_allocations(benchmark_case.operation).fdiv(ITERATIONS)
      formatter.print_result(name: benchmark_case.name, nanoseconds:, allocations:)
    end

    def validate_settings!
      {
        "ITERATIONS" => ITERATIONS,
        "WARMUP_ITERATIONS" => WARMUP_ITERATIONS,
        "SAMPLES" => SAMPLES
      }.each do |name, value|
        raise ArgumentError, "#{name} must be greater than zero, got #{value}" unless value.positive?
      end
      return if FORMATS.include?(FORMAT)

      raise ArgumentError, "FORMAT must be one of #{FORMATS.join(', ')}, got #{FORMAT.inspect}"
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def build_cases
      value = Value.new(id: 1, name: "Strict", active: true)
      equal_value = Value.new(id: 1, name: "Strict", active: true)
      verified_method = VerifiedMethod.new
      interface = Interface.new(Implementation.new)

      [
        BenchmarkCase.new("value initialization", -> { Value.new(id: 1, name: "Strict", active: true) }),
        BenchmarkCase.new("verified method call", -> { verified_method.call(value: 1) }),
        BenchmarkCase.new("interface call", -> { interface.call(value: 1) }),
        BenchmarkCase.new("to_h", -> { value.to_h }),
        BenchmarkCase.new("equality", -> { value == equal_value }),
        BenchmarkCase.new("hashing", -> { value.hash })
      ]
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def warm_up(benchmark_cases)
      benchmark_cases.each do |benchmark_case|
        repeat(WARMUP_ITERATIONS, benchmark_case.operation)
      end
    end

    def measure_times(operation)
      Array.new(SAMPLES) do
        GC.start
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        repeat(ITERATIONS, operation)
        Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      end
    end

    def measure_allocations(operation)
      GC.start
      gc_was_disabled = GC.disable
      before = GC.stat(:total_allocated_objects)
      repeat(ITERATIONS, operation)
      GC.stat(:total_allocated_objects) - before
    ensure
      GC.enable unless gc_was_disabled
    end

    def repeat(iterations, operation)
      result = nil
      iterations.times { result = operation.call }
      result
    end

    def median(values)
      sorted = values.sort
      middle = sorted.length / 2
      return sorted.fetch(middle) if sorted.length.odd?

      (sorted.fetch(middle - 1) + sorted.fetch(middle)) / 2
    end
  end
end

StrictBenchmark.run
