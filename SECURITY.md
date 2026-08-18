# Security

Report a suspected memory-safety bug privately, via a
[security advisory](https://github.com/rainlanguage/rain.solmem/security/advisories/new),
not a public issue. Every function here is `internal`, so `src/` is inlined into
the bytecode of every consuming contract, and a public report is a disclosure
against each deployment that inlined it.

Anything with no memory-safety consequence goes in a normal issue.

Fixes ship in the next release from `main`; there are no backports.
