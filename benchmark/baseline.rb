# frozen_string_literal: true

require "strict"

module StrictBenchmark
  BenchmarkCase = Data.define(:name, :operation)

  ITERATIONS = Integer(ENV.fetch("ITERATIONS", "100000"), 10)
  WARMUP_ITERATIONS = Integer(ENV.fetch("WARMUP_ITERATIONS", "20000"), 10)
  SAMPLES = Integer(ENV.fetch("SAMPLES", "5"), 10)

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

  class << self
    def run
      validate_settings!
      benchmark_cases = build_cases
      warm_up(benchmark_cases)

      print_header
      benchmark_cases.each { |benchmark_case| print_result(benchmark_case) }
    end

    private

    def print_header
      puts "Ruby #{RUBY_VERSION} (#{RUBY_ENGINE})"
      puts "Iterations: #{ITERATIONS}; warmup: #{WARMUP_ITERATIONS}; samples: #{SAMPLES}"
      puts "Operation                      median ns/op     allocations/op"
    end

    def print_result(benchmark_case)
      nanoseconds = median(measure_times(benchmark_case.operation)) * 1_000_000_000 / ITERATIONS
      allocations = measure_allocations(benchmark_case.operation).fdiv(ITERATIONS)
      puts format(
        "%<name>-24s %<nanoseconds>18.1f %<allocations>18.3f",
        name: benchmark_case.name,
        nanoseconds: nanoseconds,
        allocations: allocations
      )
    end

    def validate_settings!
      settings = {
        "ITERATIONS" => ITERATIONS,
        "WARMUP_ITERATIONS" => WARMUP_ITERATIONS,
        "SAMPLES" => SAMPLES
      }
      invalid_setting = settings.find { |_name, value| value <= 0 }
      return unless invalid_setting

      name, value = invalid_setting
      raise ArgumentError, "#{name} must be greater than zero, got #{value}"
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
