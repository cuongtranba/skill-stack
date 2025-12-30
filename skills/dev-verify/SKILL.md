---
name: dev-verify
description: Use when (1) finishing implementation work, (2) before committing code, (3) claiming a task is complete, or (4) needing to verify code changes meet quality standards.
---

# Dev Verify

**Role:** Strict development completion gatekeeper. Block until all checks pass.

**Announce:** "Verifying development completion for [scope]..."

## Trigger Modes

| Context | Behavior |
|---------|----------|
| Before commit | Auto-trigger, block commit until pass |
| `/dev-verify` invoked | Verify specified scope |
| "Done" / "Finished" claimed | Auto-trigger before confirming |

## Scope Detection (Smart Hybrid)

```
1. git diff --name-only (staged + unstaged)
2. If empty → use session-tracked files
3. Explicit override → /dev-verify src/api/
```

## Verification Checklist

**ALL checks must pass. No exceptions.**

```
┌─────────────────────────────────────────────────────┐
│  1. DETECT CHANGES                                  │
│     └─ git diff / session files / explicit scope   │
├─────────────────────────────────────────────────────┤
│  2. RUN TESTS                                       │
│     └─ Must pass 100% (zero failures)              │
├─────────────────────────────────────────────────────┤
│  3. CHECK COVERAGE DELTA                            │
│     └─ New code must be covered by tests           │
├─────────────────────────────────────────────────────┤
│  4. RUN LINT                                        │
│     └─ Auto-detect linter, zero errors             │
├─────────────────────────────────────────────────────┤
│  5. VERIFY TEST QUALITY                             │
│     └─ Invoke test-quality-verify on related tests │
└─────────────────────────────────────────────────────┘
```

## Check Details

| Check | Pass Condition | Fail Action |
|-------|----------------|-------------|
| Tests | 0 failures, 0 errors | List failing tests |
| Coverage | New lines covered | Show uncovered lines |
| Lint | 0 errors (warnings OK) | List lint errors |
| Test Quality | All tests pass review | Show rejected tests |

## Auto-Detection

### Test Runners

| Indicator | Runner | Command |
|-----------|--------|---------|
| `package.json` + jest/vitest | Jest/Vitest | `npm test` |
| `pyproject.toml` / `pytest.ini` | pytest | `pytest` |
| `go.mod` | Go test | `go test ./...` |
| `Cargo.toml` | Cargo | `cargo test` |
| `*.csproj` | dotnet | `dotnet test` |

### Linters

| Config File | Linter | Command |
|-------------|--------|---------|
| `eslint.config.*` / `.eslintrc*` | ESLint | `npx eslint [files]` |
| `pyproject.toml` (ruff) | Ruff | `ruff check` |
| `.golangci.yml` | golangci-lint | `golangci-lint run` |
| `biome.json` | Biome | `npx biome check` |
| `Cargo.toml` | Clippy | `cargo clippy` |

### Coverage

| Stack | Tool | Flag |
|-------|------|------|
| JS/TS | c8/vitest | `--coverage` |
| Python | pytest-cov | `--cov` |
| Go | go test | `-cover` |

**Fallback:** If no config detected, ask user for commands.

## Output Format

### Success

```
✓ Verifying development completion...

SCOPE: 5 files changed (3 source, 2 tests)

[1/5] Tests .......................... PASS (47 tests)
[2/5] Coverage Delta ................. PASS (new code: 94%)
[3/5] Lint ........................... PASS (0 errors)
[4/5] Test Quality ................... PASS (2 tests valid)

════════════════════════════════════════
VERIFICATION PASSED - Ready to commit
════════════════════════════════════════
```

### Failure

```
✗ Verifying development completion...

SCOPE: 5 files changed (3 source, 2 tests)

[1/5] Tests .......................... FAIL
      ├─ src/api/user.test.ts:45 - expected 200, got 404
      └─ src/api/user.test.ts:67 - timeout

[2/5] Coverage Delta ................. BLOCKED
[3/5] Lint ........................... FAIL
      └─ src/api/user.ts:23 - use 'const' instead

[4/5] Test Quality ................... BLOCKED

════════════════════════════════════════
VERIFICATION FAILED - 2 checks failed

FIX REQUIRED:
1. Fix 2 failing tests
2. Fix 1 lint error

Re-run: /dev-verify
════════════════════════════════════════
```

## Test Quality Integration

After tests pass, invoke `test-quality-verify` on:
- All test files in changed scope
- New test files (via git diff)
- Modified test files

**No Bypass:** Weak tests = verification fails.

```
[4/5] Test Quality ................... FAIL

      Test: "should return user"
      Verdict: REJECT
      Violation: Existence test
      Guidance: Assert specific user properties
```

## Edge Cases

| Situation | Behavior |
|-----------|----------|
| No tests exist | FAIL - require tests |
| No linter configured | WARN, ask to configure |
| Coverage tool missing | FAIL - require setup |
| Test-only changes | Skip coverage, run quality |
| Config-only changes | Skip all checks |

## Hard Block Rule

**If ANY check fails:**
1. Stop immediately
2. Report all issues found so far
3. Require fixes
4. No proceeding until PASS

Cannot bypass. Cannot override. Fix the issues.
