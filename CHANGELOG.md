## [Unreleased]

### Added

- Define and characterize the supported next-major API in `API.md`, provide RBS signatures for that boundary, validate them in the default checks, and add repeatable timing and allocation benchmark tooling.
- Add closed discriminated unions whose generated variants use `Strict::Value` for attributes and value behavior.
- Add inherited value and object attribute declarations and shared union attributes.
- Add structured validation violations with paths, codes, rejected values, and validators for assignment, initialization, signed method calls, and returns, plus an optional detailed-validator protocol for custom nested failures.
- Add opt-in RSpec matchers, verifying doubles, and nested matcher placeholders for Strict values and validations.

### Breaking changes

- Standardize all four capabilities on `include`: `Strict::Value`, `Strict::Object`, `Strict::Method`, and `Strict::Interface`. The legacy `extend Strict::Method` and `extend Strict::Interface` forms are outside the supported next-major API.

### Changed

- Require Ruby 3.3 or newer and test against all maintained Ruby releases.
- Update runtime and development dependencies to their latest release lines.
- Compile signed-method invocation metadata once, reuse unchanged call arguments, and consolidate generated wrappers by owner.
- Preserve validated explicit keywords when keyrest processing changes a signed call.
- Forward validated interface calls directly to implementations and compile interface-conformance expectations once per interface definition.
- Require interface implementations to cover every distinct exposed keyword parameter.
- Reduce value and object hot-path allocations during initialization, `to_h`, equality, and hashing.
- Share declaration invariants between attributes and parameters, with isolated backing storage for every distinct attribute name.
- Keep Strict configuration overrides in isolated internal execution-context storage to avoid collisions with application keys.
- Generate attribute readers and writers through one shared implementation, with mutable writers bound directly to their declarations.

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

## [0.0.0] - 2022-10-01

- Initial release
