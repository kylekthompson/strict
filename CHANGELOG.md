## [Unreleased]

### Added

- Define and characterize the supported next-major API in `API.md`, provide RBS signatures for that boundary, validate them in the default checks, and add repeatable timing and allocation benchmark tooling.

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
- Keep Strict configuration overrides in isolated internal thread-local storage to avoid collisions with application keys.
- Generate attribute readers and writers through one shared implementation, with mutable writers bound directly to their declarations.

### Performance

Representative microbenchmarks compared `90ba08a` (before) with `dff84b2` (after) on Ruby 3.3.12, with YJIT disabled. Both revisions used the same pinned harness and public workloads. Results are the median of six interleaved process-run medians; each run used 50,000 warmup iterations, 200,000 measured iterations, and nine timing samples. Allocation counts were stable across all six runs.

| Operation | `90ba08a` ns/op | `dff84b2` ns/op | Change | Allocations/op |
| --- | ---: | ---: | ---: | ---: |
| Value initialization | 4,537 | 2,017 | -56% | 11 → 4 |
| Mutable assignment | 477 | 415 | -13% | 0 → 0 |
| Verified method call | 2,384 | 1,996 | -16% | 10 → 6 |
| Interface construction | 5,582 | 1,283 | -77% | 19 → 4 |
| Interface call | 3,535 | 2,425 | -31% | 16 → 8 |
| `to_h` | 1,468 | 902 | -39% | 6 → 2 |
| Equality | 2,982 | 1,512 | -49% | 12 → 3 |
| Hashing | 2,010 | 940 | -53% | 6 → 2 |

The equal-weight geometric mean of the eight after/before timing ratios is 0.54, or 46% lower. These microbenchmarks are environment-dependent measurements, not performance guarantees.

## [0.0.0] - 2022-10-01

- Initial release
