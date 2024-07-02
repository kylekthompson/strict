# Strict

Strict provides a means to strictly validate instantiation of values, instantiation and attribute assignment of objects, and method calls at runtime.

## Installation

Install the gem and add to the application's Gemfile by executing:

```sh
$ bundle add strict
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
$ gem install strict
```

## Usage

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

### `Strict::Method`

```rb
class UpdateEmail
  extend Strict::Method

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

### `Strict::Interface`

```rb
class Storage
  extend Strict::Interface

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

storage = Storage.new(Storages::Memory.new)
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

# Locally within the block (only applies to the current thread)

Strict.with_overrides(sample_rate: 0) do
  # Use Strict as you normally would

  Strict.with_overrides(sample_rate: 0.5) do
    # Overrides can be nested
  end
end
```

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

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kylekthompson/strict. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/kylekthompson/strict/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Strict project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/kylekthompson/strict/blob/main/CODE_OF_CONDUCT.md).

## Credit

I can't thank [Tom Dalling](https://github.com/tomdalling) enough for his excellent [ValueSemantics](https://github.com/tomdalling/value_semantics) gem. Strict is heavily inspired and influenced by Tom's work and has some borrowed concepts and code.
