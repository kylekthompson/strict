# Supported API

This document defines the compatibility boundary for Strict's next major release. Code inside this boundary is public API. Other reachable Ruby constants, methods, generated modules, and reflection details are implementation details unless this document identifies them as public.

## Capabilities

Bring each Strict capability into a class with `include`:

```ruby
include Strict::Value
include Strict::Object
include Strict::Method
include Strict::Interface
include Strict::Union
```

The former `extend Strict::Method` and `extend Strict::Interface` forms are not part of this major-version API.

### Values and objects

`Strict::Value` and `Strict::Object` add an `attributes` declaration block. Each declaration accepts an attribute name, an optional validator, `coerce:`, and one of `default:`, `default_value:`, or `default_generator:`.

Attribute names can be ordinary identifiers, Ruby reserved words declared through `strict_attribute`, or names ending in `?` or `!`. Each distinct name has independent backing storage, including names that differ only by a trailing `?` or `!`. A mutable object's punctuation writer can be called with `public_send`, for example `object.public_send(:"active?=", false)`.

Both capabilities provide:

- keyword initialization that rejects missing, additional, or invalid attributes;
- declared readers;
- coercion before validation;
- `to_h`, with symbol keys in declaration order;
- a meaningful `inspect` and pretty-print representation, without a fixed formatting contract;
- class methods `strict_attributes` and `coercer`.

`Strict::Object` also provides validated writers. It retains Ruby's identity equality and does not provide `with`.

`Strict::Value` does not provide writers. It provides:

- `with(**attributes)`, which returns a validated instance of the same class;
- `deconstruct_keys(keys)`, for Ruby hash and class patterns;
- `==` and `eql?`, based on exact class and attribute values;
- `hash`, consistent with `eql?`.

A subclass inherits its parent's attributes. A subclass `attributes` block adds its declarations after the inherited declarations without changing the parent. Attribute redeclaration, multiple `attributes` blocks on the same class, and generated-method collisions are outside the compatibility boundary.

#### Attribute introspection

`strict_attributes` is an ordered `Enumerable`. Each yielded descriptor supports:

- `name`
- `validator`
- `optional?`

The descriptor's concrete class and other methods are implementation details.

#### Defaults

- `default: value` uses the value directly.
- `default: callable` calls it for each default.
- `default_value: value` preserves the value even when it is callable.
- `default_generator: callable` calls it for each default.

Only one default option can be present on one declaration.

#### Attribute coercion

`coerce:` accepts:

- a callable;
- a class method name as a symbol;
- `true`, which calls the class method `coerce_<attribute>`.

The generated class `coercer` returns `nil` and non-hash-like values unchanged. For hash-like input, it recognizes declared symbol or string keys and initializes the class with those values.

### Discriminated unions

`Strict::Union` defines a closed, discriminated union of generated value-object variants. A union must declare one discriminator before it declares variants:

```ruby
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
```

There is no default discriminator. A union can declare zero or one `attributes` block before its variants. Strict shares these attributes across every variant. The declaration can appear before or after the discriminator, but it cannot redeclare the discriminator.

A variant name must be a lower snake-case string or symbol, and Strict generates its PascalCase nested subclass. By default, the discriminator tag is the name's corresponding symbol. The optional `tag:` can assign a different string or symbol. For example, `variant :requires_action, tag: "action-required"` generates `PaymentResult::RequiresAction < PaymentResult` with the tag `"action-required"`.

The variant block configures the generated subclass. It can include modules, define methods, and contain zero or one `attributes` block. Strict combines the discriminator, shared union attributes, and variant attributes in that order. The discriminator is an implicit first attribute with a fixed default value:

```ruby
PaymentResult::Authorized.new(
  request_id: "request_123",
  authorization_id: "auth_123",
  amount_in_cents: 1_000
).to_h
# => { status: "payment.authorized", request_id: "request_123", authorization_id: "auth_123", amount_in_cents: 1_000 }
```

Variants therefore use the documented `Strict::Value` behavior for initialization, validation, coercion, defaults, copying, equality, hashing, conversion, inspection, and pattern matching. A variant declaration cannot redeclare the discriminator. The union base cannot be instantiated directly.

`PaymentResult === value` is true only when `value` has the exact class of a registered variant. Generated variant classes retain normal Ruby class matching, including matching instances of their subclasses. Union and variant inheritance are outside the compatibility boundary.

The union class `coercer`:

- returns `nil` and non-hash-like values unchanged;
- returns an existing exact union member unchanged;
- accepts the discriminator as a symbol or string key;
- accepts a registered tag as its equivalent symbol or string value and stores its configured form;
- dispatches hash-like input through the selected variant's value coercer;
- raises `ArgumentError` when the discriminator is missing or unknown.

A union class can be an attribute or method validator. Add its coercer when the declaration must also accept hash-like input:

```ruby
payment_result PaymentResult
coerced_payment_result PaymentResult, coerce: PaymentResult.coercer
```

Declaring a discriminator more than once, declaring equivalent duplicate string or symbol tags, using an invalid variant name or tag, replacing an existing generated constant, declaring multiple union or variant attribute blocks, declaring union attributes after a variant, or redeclaring the discriminator raises `ArgumentError`. Declaration return values, generated-class reflection details, and the exact text of declaration and coercion errors are outside the compatibility boundary.

### Signed methods

`Strict::Method` adds `sig`, which applies to the next instance or singleton method definition. A signature supports required and optional positional parameters, `*rest`, required and optional keyword parameters, `**keyrest`, and an optional `returns` declaration. Blocks pass through without validation.

Parameter declarations accept a validator, a callable `coerce:`, and the three default forms described above. `strict_parameter` supports names that cannot be expressed as ordinary calls in the DSL.

Strict verifies that signature names match the method definition. Calls coerce parameters, validate parameters, invoke the method, and validate its return value. A signature with no `returns` declaration accepts any return value.

Inherited signed methods remain validated. A subclass override is unsigned unless the subclass provides a new signature.

The following behavior is outside the compatibility boundary:

- return-value coercion;
- private or protected signed methods;
- duplicate parameter declarations;
- repeated signatures or same-class method redefinition;
- DSL expression return values;
- generated wrapper owners, ancestors, parameters, source locations, or other reflection details.

### Interfaces

`Strict::Interface` adds `expose` and `.coercer`. `expose(name) { ... }` defines a validated, keyword-forwarding instance method.

Constructing an interface requires an implementation. The implementation must respond publicly to every exposed method. Its explicit parameters must be the required keywords declared by the interface. A keyword-rest parameter satisfies keyword coverage. Additional ordinary implementation methods, blocks, and a positional-rest parameter do not affect conformance.

Interface instances expose their `implementation`. The class coercer:

- returns `nil` unchanged;
- returns an instance of that exact interface unchanged;
- otherwise wraps the value and checks conformance.

Interface subclassing and re-exposing a method are outside the compatibility boundary.

## Validators and coercers

Any object that implements `===` can be a validator. This includes classes, modules, literals, and custom validators.
When a custom validator rejects a value, Strict reports that validator in one `:invalid` violation. A custom validator does not need to implement a separate failure protocol.

Attribute and method DSL blocks provide these validator constructors:

- `AllOf(*validators)`
- `AnyOf(*validators)`
- `Anything()`
- `ArrayOf(element_validator)`
- `Boolean()`
- `HashOf(key_validator => value_validator)`
- `RangeOf(element_validator)`

They also provide these coercer constructors:

- `ToArray(with: nil)`
- `ToHash(with_keys: nil, with_values: nil)`

The constructors' validation and conversion results are public. Their concrete `Strict::Validators::*` and `Strict::Coercers::*` classes, metadata readers, and exact string representations are not public API.

## Configuration

Strict provides:

- `Strict.configuration`
- `Strict.configure { |configuration| ... }`
- `Strict.with_overrides(**options) { ... }`

The supported configuration options are `random` and `sample_rate`, with readers and writers. `random` must implement `Random::Formatter`. `sample_rate` must be in the inclusive range from `0` through `1`.

Overrides are local to the current thread, can be nested, and are restored when a block returns or raises. An active override cannot be changed with `Strict.configure`.

Sampling controls validator calls. Coercion, signature-definition checks, and interface conformance checks still run when validation is sampled out.

Direct construction of `Strict::Configuration`, its `validate?` and `to_h` methods, block return values, and configuration object identity are outside the compatibility boundary.

## Exceptions

These exception classes are public and inherit from `Strict::Error`:

- `Strict::AssignmentError`
- `Strict::InitializationError`
- `Strict::ImplementationDoesNotConformError`
- `Strict::MethodCallError`
- `Strict::MethodDefinitionError`
- `Strict::MethodReturnError`

Messages identify the failure but their exact wording and formatting are not fixed. Exception constructor signatures are internal.

Every `Strict::Error` provides `#violations`, which returns an array of `Strict::Violation` records. Assignment, initialization, method-call, and method-return errors report runtime validation and structural input failures. Other errors return an empty array.

Each violation provides:

- `path`: the location of the failure;
- `code`: `:invalid`, `:missing`, or `:unexpected`;
- `value`: the rejected or unexpected value, or `nil` for a missing value;
- `validator`: the validator that rejected or required the value, or `nil` for an unexpected value.

An attribute or parameter name is the first path segment. Array elements use zero-based indices, and hash entries use their actual keys. Unexpected positional arguments use their zero-based argument indices. Return values start at the root, so a simple invalid return has an empty path and a nested return starts with its collection segment. `ArrayOf`, `HashOf`, and `AllOf` preserve nested failure paths. Failure order is not fixed.

The supported readers are:

- `AssignmentError#value`
- `InitializationError#remaining_attributes` and `#missing_attributes`
- `ImplementationDoesNotConformError#interface`, `#receiver`, `#missing_methods`, and `#invalid_method_definitions`
- `MethodCallError#remaining_args`, `#remaining_kwargs`, and `#missing_parameters`
- `MethodDefinitionError#missing_parameters` and `#additional_parameters`
- `MethodReturnError#value`

Readers that expose attribute, parameter, or method descriptors are internal.

## Constants and implementation details

`Strict::VERSION` and `Strict::Violation` are public. `Strict::ISSUE_TRACKER` is internal.

`Strict::Attribute`, `Strict::Parameter`, `Strict::Return`, `strict_class_methods`, and `strict_instance_methods` are internal. The `Strict::Accessor`, `Strict::Reader`, `Strict::Attributes`, `Strict::Dsl`, `Strict::Interfaces`, `Strict::Methods`, and `Strict::Unions` namespaces and their contents are also internal.
