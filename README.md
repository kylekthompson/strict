# Strict

Strict provides a means to strictly validate instantiation of values, instantiation and attribute assignment of objects, and method calls at runtime.

## Installation

Strict requires Ruby 3.3 or newer.

Install the gem and add to the application's Gemfile by executing:

```sh
$ bundle add strict
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
$ gem install strict
```

## Usage

See [Supported API](API.md) for the next major release's compatibility boundary.

### `Strict::Value`

```rb
class Money
  include Strict::Value

  attributes do
    amount_in_cents Integer
    currency AnyOf("USD", "CAD"), default: "USD"
  end
end

Money.new(amount_in_cents: 100_00)
# => #<Money amount_in_cents=100_00 currency="USD">

Money.new(amount_in_cents: 100_00, currency: "CAD")
# => #<Money amount_in_cents=100_00 currency="CAD">

Money.new(amount_in_cents: 100.00)
# => Strict::InitializationError

Money.new(amount_in_cents: 100_00).with(amount_in_cents: 200_00)
# => #<Money amount_in_cents=200_00 currency="USD">

Money.new(amount_in_cents: 100_00).amount_in_cents = 50_00
# => NoMethodError

Money.new(amount_in_cents: 100_00) == Money.new(amount_in_cents: 100_00)
# => true
```

Subclasses can add attributes while retaining their inherited attributes:

```rb
class Person
  include Strict::Value

  attributes do
    name String
  end
end

class Employee < Person
  attributes do
    employee_id String
  end
end
```

### `Strict::Union`

```rb
class PaymentResult
  include Strict::Union

  discriminator :status

  attributes do
    request_id String
  end

  variant :authorized, tag: "payment.authorized" do
    attributes do
      authorization_id String
      amount_in_cents Integer
    end

    def successful? = true
  end

  variant :declined do
    attributes do
      reason String
    end

    def successful? = false
  end
end

authorized = PaymentResult::Authorized.new(
  request_id: "request_123",
  authorization_id: "auth_123",
  amount_in_cents: 1_000
)
authorized.to_h
# => { status: "payment.authorized", request_id: "request_123", authorization_id: "auth_123", amount_in_cents: 1_000 }

authorized.successful?
# => true

result = PaymentResult.coercer.call(
  "status" => "declined",
  "request_id" => "request_456",
  "reason" => "insufficient_funds"
)
# => #<PaymentResult::Declined status=:declined request_id="request_456" reason="insufficient_funds">

case result
in PaymentResult::Authorized(authorization_id:)
  authorization_id
in PaymentResult::Declined(reason:)
  reason
end
# => "insufficient_funds"
```

### `Strict::Object`

```rb
class Stateful
  include Strict::Object

  attributes do
    some_state String
    dependency Anything(), default: nil
  end
end

Stateful.new(some_state: "123")
# => #<Stateful some_state="123" dependency=nil>

Stateful.new(some_state: "123").with(some_state: "456")
# => NoMethodError

Stateful.new(some_state: "123").some_state = "456"
# => "456"
# => #<Stateful some_state="456" dependency=nil>

Stateful.new(some_state: "123").some_state = 456
# => Strict::AssignmentError

Stateful.new(some_state: "123") == Stateful.new(some_state: "123")
# => false
```

Validation errors provide structured violations with paths into nested values:

```rb
class Batch
  include Strict::Value

  attributes do
    labels ArrayOf(String)
  end
end

begin
  Batch.new(labels: ["ready", 404], extra: true)
rescue Strict::InitializationError => error
  error.violations.map do |violation|
    [violation.path, violation.code, violation.value, violation.validator]
  end
end
# => [
#      [[:labels, 1], :invalid, 404, String],
#      [[:extra], :unexpected, true, nil]
#    ]
```

The codes are `:invalid`, `:missing`, and `:unexpected`. Custom validators only need to implement `===`; Strict reports a rejected value against that validator at the current path. A custom validator can include `Strict::DetailedValidator` and implement `violations(value)` when it needs to report relative nested paths:

```rb
class Emails
  include Strict::DetailedValidator

  def violations(value)
    unless Array === value
      return [Strict::Violation.new(path: [], code: :invalid, value: value, validator: Array)]
    end

    value.each_with_index.filter_map do |email, index|
      next if String === email

      Strict::Violation.new(path: [index], code: :invalid, value: email, validator: String)
    end
  end
end
```

The module provides `===` from `violations`, and Strict prefixes each relative path with its enclosing attribute, parameter, or collection path.

When an attribute or parameter validator provides a `.coercer`, Strict uses it automatically before validation. An explicit `coerce:` value overrides it, and `coerce: false` disables it. This lets nested Strict values, unions, and interfaces accept the input handled by their class coercers without repeating `coerce:` in each declaration. `ArrayOf` and `HashOf` propagate coercers from their element, key, and value validators, so compositions such as `ArrayOf(ValueClass)` also coerce automatically.

### `Strict::Method`

```rb
class UpdateEmail
  include Strict::Method

  sig do
    user_id String, coerce: ->(value) { value.to_s }
    email String
    returns AnyOf(true, nil)
  end
  def call(user_id:, email:)
    # contrived logic
    user_id == email
  end
end

UpdateEmail.new.call(user_id: 123, email: "123")
# => true

UpdateEmail.new.call(user_id: "123", email: "123")
# => true

UpdateEmail.new.call(user_id: "123", email: 123)
# => Strict::MethodCallError

UpdateEmail.new.call(user_id: "123", email: "456")
# => Strict::MethodReturnError
```

`returns` validates the exact value produced by the method. It never coerces or replaces that value, and a successful call returns the same object to the caller.

### `Strict::Interface`

```rb
class Storage
  include Strict::Interface

  expose(:write) do
    key String
    contents String
    returns Boolean()
  end

  expose(:read) do
    key String
    returns AnyOf(String, nil)
  end
end

module Storages
  class Memory
    def initialize
      @storage = {}
    end

    def write(key:, contents:)
      storage[key] = contents
      true
    end

    def read(key:)
      storage[key]
    end

    private

    attr_reader :storage
  end
end

adapter = Storages::Memory.new

Storage.implemented_by?(adapter)
# => true

Storage.verify_implementation!(adapter)
# => nil

storage = Storage.new(adapter)
# => #<Storage implementation=#<Storages::Memory>>

storage.write(key: "some/path/to/file.rb", contents: "Hello")
# => true

storage.write(key: "some/path/to/file.rb", contents: {})
# => Strict::MethodCallError

storage.read(key: "some/path/to/file.rb")
# => "Hello"

storage.read(key: "some/path/to/other.rb")
# => nil

module Storages
  class Wat
    def write(key:)
    end
  end
end

storage = Storage.new(Storages::Wat.new)
# => Strict::ImplementationDoesNotConformError
```

### RSpec extensions

Strict provides supported, opt-in integration with RSpec 3.13. RSpec remains an optional dependency and is not loaded by
`require "strict"`. Add RSpec to the test bundle:

```rb
group :test do
  gem "rspec", "~> 3.13"
end
```

Then require the adapter from the spec helper:

```rb
require "strict/rspec"
```

The adapter provides matchers for validators and interfaces:

```rb
expect(String).to validate("value")
expect(String).not_to validate(1)

expect(Storages::Memory.new).to conform_to(Storage)
expect(Object.new).not_to conform_to(Storage)
```

When validation fails, `validate` uses `Strict::Violation` records to report root and nested
`Strict::DetailedValidator` failure paths.

`strict_double` builds an RSpec verifying double. For an interface, it stubs every exposed method to `nil` unless a
different result is provided, so the double conforms without extra setup:

```rb
storage = strict_double(Storage, write: true, read: "contents")

expect(storage).to conform_to(Storage)
Storage.new(storage).read(key: "some/path")
# => "contents"
```

RSpec instance doubles also satisfy Strict class validators for attributes, signed parameters, and return values. Plain
doubles remain invalid:

```rb
class Item
  include Strict::Value

  attributes do
    sku String
  end
end

class Shipment
  include Strict::Value

  attributes do
    item Item
  end
end

item = instance_double(Item, sku: "item_123")
Shipment.new(item: item)
# => #<Shipment item=#<InstanceDouble(Item)>>

Shipment.new(item: double("item"))
# => Strict::InitializationError
```

Matcher objects can also stand in for validated fields or elements of built-in collection validators when constructing
expected Strict values. RSpec recursively applies the nested matchers in argument expectations:

```rb
expect(dispatcher).to have_received(:ship).with(
  shipment: Shipment.new(
    item: have_attributes(sku: "item_123")
  )
)
```

This composition does not change normal Strict value equality or hashing.

### Configuration

Strict exposes some configuration options which can be configured globally via `Strict.configure { ... }` or overridden
within a block via `Strict.with_overrides(...) { ... }`.

#### Example

```ruby
# Globally

Strict.configure do |c|
  c.sample_rate = 0.75 # run validation ~75% of the time
end

Strict.configure do |c|
  c.sample_rate = 0 # disable validation (Strict becomes Lenient)
end

Strict.configure do |c|
  c.sample_rate = 1 # always run validation
end

# Locally within the block (only applies to the current execution context)

Strict.with_overrides(sample_rate: 0) do
  # Use Strict as you normally would

  Strict.with_overrides(sample_rate: 0.5) do
    # Overrides can be nested
  end
end
```

Overrides are local to the current execution context (fiber). They can be nested and are restored when a block returns
or raises. Neither a newly created fiber nor a new thread inherits an active override.

#### `Strict.configuration.random`

The instance of a `Random::Formatter` that Strict uses in tandom with the `sample_rate` to determine when validation
should be checked.

**Default**: `Random.new`

#### `Strict.configuration.sample_rate`

The rate of samples Strict will consider when validating attributes, parameters, and return values. A rate of 0.25 will
validate roughly 25% of the time, a rate of 0 will disable validation entirely, and a rate of 1 will always
run validations. The `sample_rate` is used in tandem with `random` to determine whether validation should be run.

**Default**: 1

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the specs. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Run `bundle exec rake benchmark` to measure baseline timing and allocations for value initialization, mutable assignment, verified method calls, interface construction, interface calls, `to_h`, equality, and hashing. Set `ITERATIONS`, `WARMUP_ITERATIONS`, or `SAMPLES` to change the workload, and set `FORMAT=markdown` to produce a Markdown table. Pull requests publish this table in a non-blocking job summary and upload it as an artifact. These benchmarks report measurements only and do not enforce thresholds.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kylekthompson/strict. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/kylekthompson/strict/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Strict project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/kylekthompson/strict/blob/main/CODE_OF_CONDUCT.md).

## Credit

I can't thank [Tom Dalling](https://github.com/tomdalling) enough for his excellent [ValueSemantics](https://github.com/tomdalling/value_semantics) gem. Strict is heavily inspired and influenced by Tom's work and has some borrowed concepts and code.
