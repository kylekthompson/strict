# frozen_string_literal: true

module Strict
  module Interface
    def self.extended(mod)
      mod.extend(Strict::Method)
      mod.include(Interfaces::Instance)
    end

    def expose(method_name, &)
      sig = sig(&)
      parameter_list = sig.parameters.map { |parameter| "#{parameter.name}:" }.join(", ")

      module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        def #{method_name}(#{parameter_list}, &block)              # def method_name(one:, two:, three:, &block)
          implementation.#{method_name}(#{parameter_list}, &block) #   implementation.method_name(one:, two:, three:, &block)
        end                                                        # end
      RUBY
    end
  end
end
