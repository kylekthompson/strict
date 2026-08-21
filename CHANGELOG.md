## [Unreleased]

## [2.1.0] - 2026-08-21

### Added

- Add class-level convenience constructors and instance interrogation methods for every `Strict::Union` variant.

## [2.0.0] - 2026-08-20

### Added

- Define and characterize the supported 2.0 API in `API.md`, provide RBS signatures for that boundary, validate them in the default checks, and add repeatable timing and allocation benchmark tooling.
- Add closed discriminated unions whose generated variants use `Strict::Value` for attributes and value behavior.
- Add inherited value and object attribute declarations and shared union attributes.
- Add structured validation violations with paths, codes, rejected values, and validators for assignment, initialization, signed method calls, and returns, plus an optional detailed-validator protocol for custom nested failures.
- Add opt-in RSpec matchers, verifying doubles, and nested matcher placeholders for Strict values and validations.
- Add `implemented_by?` and `verify_implementation!` to check interface adapters without constructing an interface.

### Breaking changes

- Standardize all four capabilities on `include`: `Strict::Value`, `Strict::Object`, `Strict::Method`, and `Strict::Interface`. The legacy `extend Strict::Method` and `extend Strict::Interface` forms are outside the supported 2.0 API.
- Make signed method returns validate-only. `returns` rejects coercion options, validates the original result, and preserves its identity for the caller.
- Reject malformed or same-block duplicate attribute declarations, repeated attribute blocks, duplicate or repeated signatures, and same-class or Strict/core-reserved generated attribute method collisions with `ArgumentError` instead of silently replacing declarations or installing pathological methods.

### Changed

- Require Ruby 3.3 or newer and test against all maintained Ruby releases.
- Update development dependencies to their latest release lines while retaining Zeitwerk 2.x compatibility from 2.6 onward.
- Compile signed-method invocation metadata once, reuse unchanged call arguments, and consolidate generated wrappers by owner.
- Preserve validated explicit keywords when keyrest processing changes a signed call.
- Forward validated interface calls directly to implementations and compile interface-conformance expectations once per interface definition.
- Check interface implementation signatures by substitutability: require every exposed keyword and reject only additional parameters that can constrain a valid interface call.
- Reduce value and object hot-path allocations during initialization, `to_h`, equality, and hashing.
- Share declaration invariants between attributes and parameters, preserve conventional attribute backing instance variables, and reject attribute names that map to the same storage.
- Automatically use a validator's coercer for attributes and parameters unless the declaration overrides or disables coercion.
- Propagate default coercion through `ArrayOf` elements and `HashOf` keys and values.
- Keep Strict configuration overrides in isolated internal execution-context storage to avoid collisions with application keys.
- Generate attribute readers and writers through one shared implementation, with mutable writers bound directly to their declarations.
- Allow generated attribute readers and writers to override inherited public, protected, and private methods while continuing to reject same-class and Strict/core-reserved collisions.
- Allow value and object subclasses to redefine inherited attributes without changing the parent or attribute order.
- Return exact `Strict::Value` and `Strict::Object` instances unchanged from their class coercers while continuing to convert subclass instances.
- Validate declaration names, explicit default generators, and capability-specific coercer forms before installing attributes or signatures.

### Performance

Representative microbenchmarks compared `90ba08a` (before) with `daa388d` (after) on Ruby 3.3.12, with YJIT disabled. Both revisions used the same pinned harness and public workloads. Results are the median of six interleaved process-run medians; each run used 50,000 warmup iterations, 200,000 measured iterations, and nine timing samples. Allocation counts were stable across all six runs.

| Operation | `90ba08a` ns/op | `daa388d` ns/op | Change | Allocations/op |
| --- | ---: | ---: | ---: | ---: |
| Value initialization | 4,339 | 2,017 | -54% | 11 → 4 |
| Mutable assignment | 456 | 431 | -5% | 0 → 0 |
| Verified method call | 2,118 | 1,981 | -6% | 10 → 6 |
| Interface construction | 5,054 | 1,145 | -77% | 19 → 4 |
| Interface call | 3,230 | 2,340 | -28% | 16 → 8 |
| `to_h` | 1,301 | 852 | -35% | 6 → 2 |
| Equality | 2,786 | 1,433 | -49% | 12 → 3 |
| Hashing | 1,847 | 926 | -50% | 6 → 2 |

The equal-weight geometric mean of the eight after/before timing ratios is 0.57, or 43% lower. These microbenchmarks are environment-dependent measurements, not performance guarantees.

## [1.5.0] - 2023-04-12

### Added

- Add global configuration through `Strict.configure` and nested, thread-local overrides through `Strict.with_overrides`.
- Add configurable validation sampling for attributes, parameters, and return values through `sample_rate` and `random`.

## [1.4.0] - 2022-11-02

### Changed

- Allow interface implementations to use `*args` and `**kwargs` for parameters they do not declare directly, while continuing to validate calls made through the interface.

## [1.3.1] - 2022-10-20

### Fixed

- Support parameterless methods in `Strict::Interface` without generating invalid method syntax.

## [1.3.0] - 2022-10-18

### Added

- Add `.coercer` to classes that extend `Strict::Interface` so they can validate and wrap implementations through the coercion protocol.

## [1.2.0] - 2022-10-14

### Changed

- Support Ruby 3.0 and newer instead of requiring Ruby 3.1 or newer.

## [1.1.0] - 2022-10-14

### Added

- Add `Strict::Interface` for defining validated interfaces and checking that implementations conform to their exposed methods.
- Add coercers for `Strict::Value` and `Strict::Object` classes and for array and hash values.

## [1.0.0] - 2022-10-12

### Added

- Publish the initial Strict release with immutable `Strict::Value` classes, mutable `Strict::Object` classes, and runtime method-call validation through `Strict::Method`.
- Add the attribute and method-signature DSLs, built-in validators, coercion, structured errors, value equality and cloning, and object assignment validation.

## [0.0.0] - 2022-10-01

- Start initial development.

[Unreleased]: https://github.com/kylekthompson/strict/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/kylekthompson/strict/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/kylekthompson/strict/compare/v1.5.0...v2.0.0
[1.5.0]: https://github.com/kylekthompson/strict/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/kylekthompson/strict/compare/v1.3.1...v1.4.0
[1.3.1]: https://github.com/kylekthompson/strict/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/kylekthompson/strict/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/kylekthompson/strict/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/kylekthompson/strict/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/kylekthompson/strict/releases/tag/v1.0.0
[0.0.0]: https://github.com/kylekthompson/strict/commit/27fbe42e0d0d3c5ce86493e1252cf889f5a746d9
