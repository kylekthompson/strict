# frozen_string_literal: true

class AccessorClass
  extend Strict::Accessor::Attributes

  attributes do
    foo Integer
    bar String, coerce: :some_coercer
    baz String, default: "some string"
  end

  def self.some_coercer(value)
    value.to_s
  end
end

class ObjectClass
  include Strict::Object

  attributes do
    foo Integer
    bar String, coerce: :some_coercer
    baz String, default: "some string"
  end

  def self.some_coercer(value)
    value.to_s
  end
end

class ReaderClass
  extend Strict::Reader::Attributes

  attributes do
    foo Integer
    bar String, coerce: :some_coercer
    baz String, default: "some string"
  end

  def self.some_coercer(value)
    value.to_s
  end
end

class ValueClass
  include Strict::Value

  attributes do
    foo Integer
    bar String, coerce: :some_coercer
    baz String, default: "some string"
  end

  def self.some_coercer(value)
    value.to_s
  end
end

class OtherValueClass
  include Strict::Value

  attributes do
    foo Integer
    bar String, coerce: :some_coercer
    baz String, default: "some string"
  end

  def self.some_coercer(value)
    value.to_s
  end
end
