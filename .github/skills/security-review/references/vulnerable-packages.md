# Dependency vulnerability review

Load this during Step 2 (Dependency Audit).

Static package/version watchlists become unsafe quickly and must never be used
to declare a dependency clean. Treat the project's resolved lockfile plus a
current advisory database as authoritative.

## Required method

1. Identify every package manifest and lockfile.
2. Use the repository's existing lockfile-aware audit command when available.
3. Correlate findings with current GitHub Advisory Database, OSV, vendor or
   ecosystem advisories.
4. Report the resolved vulnerable version, advisory identifier, affected
   range, fixed version when one exists, and whether the package is reachable.
5. If advisory data cannot be queried, state that dependency vulnerability
   status is **unverified**. Never infer safety from a minimum version in this
   file.

## Ecosystem sources

| Ecosystem | Preferred lockfile-aware evidence |
| --- | --- |
| npm / Node.js | Existing `npm audit`, pnpm or Yarn audit output; GitHub Advisory Database; OSV |
| Python / pip | Existing `pip-audit` or equivalent output; PyPA advisories; OSV |
| .NET / NuGet | Existing `dotnet list package --vulnerable` output; GitHub Advisory Database |
| Java / Maven or Gradle | Existing OWASP Dependency-Check or configured ecosystem audit; OSV |
| Ruby / Bundler | Existing `bundler-audit` output; Ruby Advisory Database |
| Rust / Cargo | Existing `cargo audit` output; RustSec |
| Go modules | Existing `govulncheck` output; Go Vulnerability Database |

Do not add a new scanner solely for a review unless the repository owner
approves the dependency and CI change.

## Supply-chain signals to flag regardless of version

- install or lifecycle scripts that download and execute remote content;
- unexpected native compilation or binary downloads;
- dependencies from unknown publishers or lookalike package names;
- unpinned Git, URL or mutable-tag dependencies;
- packages that are deprecated, archived or have an active takeover warning;
- lockfile changes that introduce unrelated transitive dependencies;
- dependency confusion exposure through mixed public/private registries;
- packages used as a security boundary despite explicit sandbox disclaimers.

## Verification links

- GitHub Advisory Database: https://github.com/advisories
- OSV: https://osv.dev/
- RustSec: https://rustsec.org/advisories/
- Go Vulnerability Database: https://vuln.go.dev/
