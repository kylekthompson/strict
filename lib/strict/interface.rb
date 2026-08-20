# frozen_string_literal: true

module Strict
  module Interface
    def self.included(mod)
      mod.include(Strict::Method)
      mod.include(Interfaces::Instance)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def coercer
        Interfaces::Coercer.new(self)
      end

      # rubocop:disable Metrics/MethodLength
      def expose(method_name, &)
        sig = sig(&)
        parameter_list = [
          *sig.parameters.map { |parameter| "#{parameter.name}:" },
          "&block"
        ].join(", ")
        argument_list = sig.parameters.map do |parameter|
          "#{parameter.name.inspect} => binding.local_variable_get(#{parameter.name.inspect})"
        end.join(", ")

        module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def #{method_name}(#{parameter_list})                                            # def method_name(one:, two:, &block)
            implementation.public_send(#{method_name.inspect}, **{#{argument_list}}, &block) #   implementation.public_send(:method_name, **arguments, &block)
          end                                                                              # end
        RUBY
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
