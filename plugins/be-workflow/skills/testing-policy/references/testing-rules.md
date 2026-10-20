## Testing policy

- Derive expected behavior from approved requirements and contracts, not by
  copying the current implementation's output. Report undefined expectations.
- Verify changed functionality and important calculations, access decisions,
  and state transitions. Reuse sufficient existing tests instead of duplicating them.
- Select relevant input partitions, boundaries, condition combinations, and
  failure paths. Do not mechanically add a test for every function or internal branch.
- Use the smallest test level that proves the behavior. Add integration or E2E
  coverage when the changed contract requires it; mocked calls do not prove real
  persistence, transaction, cache, or external integration behavior.
- Give tests clear behavior, condition, and expected-result names. Assert observable
  outcomes and contractually required interactions. Control time, external services,
  and shared state so tests are repeatable.
- For bug fixes, add or identify a regression test that distinguishes the defect.
  When feasible, confirm failure on the pre-fix code and success on the fixed code.
  This may be checked after implementation; do not overwrite shared work to do it.
  Report if pre-fix verification was not possible.
- Test and implementation order is flexible unless the user explicitly requests
  a sequence. A first-run pass is not itself invalid; a failing test before coding
  and separate test authors are not required by default.
- Run the changed-behavior tests and affected regression checks using repository
  commands. Report commands, actual results, unrun checks, and reasons.
- Do not weaken assertions, skip tests, or disable behavior merely to pass checks.
  Correct obsolete expectations only with requirements evidence and the workflow's
  change authority. Separate pre-existing failures from failures caused by the change.
