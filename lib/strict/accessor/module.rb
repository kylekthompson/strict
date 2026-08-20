# frozen_string_literal: true

module Strict
  module Accessor
    class Module < ::Module
      attr_reader :configuration

      # rubocop:disable Metrics/MethodLength
      def initialize(configuration)
        super()

        @configuration = configuration
        const_set(Strict::Attributes::Class::CONSTANT, configuration)
        configuration.attributes.each do |attribute|
          module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def #{attribute.name}            # def name
              #{attribute.instance_variable} #   @instance_variable
            end                              # end
          RUBY

          if attribute.name.end_with?("?", "!")
            define_writer(attribute)
          else
            module_eval(<<~RUBY, __FILE__, __LINE__ + 1)
              def #{attribute.name}=(value)                                         # def name=(value)
                attribute = self.class.strict_attributes.named!(:#{attribute.name}) #   attribute = self.class.strict_attributes.named!(:name)
                value = attribute.coerce(value, for_class: self.class)              #   value = attribute.coerce(value, for_class: self.class)
                if attribute.valid?(value)                                          #   if attribute.valid?(value)
                  #{attribute.instance_variable} = value                            #     @instance_variable = value
                else                                                                #   else
                  raise Strict::AssignmentError.new(                                #     raise Strict::AssignmentError.new(
                    assignable_class: self.class,                                   #       assignable_class: self.class,
                    invalid_attribute: attribute,                                   #       invalid_attribute: attribute,
                    value: value                                                    #       value: value
                  )                                                                 #     )
                end                                                                 #   end
              end                                                                   # end
            RUBY
          end
        end
      end
      # rubocop:enable Metrics/MethodLength

      def inspect
        "#<#{self.class} (#{configuration.attributes.map(&:name).join(', ')})>"
      end

      private

      # rubocop:disable Metrics/MethodLength
      def define_writer(attribute)
        attribute_name = attribute.name
        define_method(:"#{attribute_name}=") do |value|
          descriptor = self.class.strict_attributes.named!(attribute_name)
          value = descriptor.coerce(value, for_class: self.class)
          if descriptor.valid?(value)
            instance_variable_set(descriptor.instance_variable, value)
          else
            raise Strict::AssignmentError.new(
              assignable_class: self.class,
              invalid_attribute: descriptor,
              value: value
            )
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
