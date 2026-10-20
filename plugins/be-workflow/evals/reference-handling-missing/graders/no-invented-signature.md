---
type: regex
target: { source: file, path: docs/CHK-1/plan.md }
pattern: '\bnormalize\s*\([^)\n]*\)\s*;'
match: not_contains
---
