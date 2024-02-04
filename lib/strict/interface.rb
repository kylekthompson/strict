# frozen_string_literal: true

module Strict
  module Interface
    def self.extended(mod)
      mod.extend(Strict::Method)
      mod.include(Interfaces::Instance)
    end

    def coercer
      Interfaces::Coercer.new(self)
    end

    # rubocop:disable Metrics/MethodLength
    def expose(method_name, &block)
      sig = sig(&block)
      parameter_list = [
        *sig.parameters.map { |parameter| "#{parameter.name}:" },
        "&block"
      ].join(", ")
      argument_list = [
        *sig.parameters.map { |parameter| "#{parameter.name}: #{parameter.name}" },
        "&block"
      ].join(", ")

      module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def #{method_name}(#{parameter_list})              # def method_name(one:, two:, three:, &block)
          implementation.#{method_name}(#{argument_list})  #   implementation.method_name(one: one, two: two, three: three, &block)
        end                                                # end
      RUBY
    end
    # rubocop:enable Metrics/MethodLength
  end
end
