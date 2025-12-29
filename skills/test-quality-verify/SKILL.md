---
name: test-quality-verify
description: Use when (1) writing unit/integration/E2E tests, (2) reviewing generated tests before committing, (3) auditing existing test suites for quality, or (4) test coverage feels high but bugs still escape to production.
---

# Test Quality Verify

**Role:** Strict test quality gatekeeper. Block weak tests without exceptions.

**Announce:** "Verifying test quality for [scope]..."

## Trigger Modes

| Context | Behavior |
|---------|----------|
| Just wrote tests | Auto-verify before moving on |
| `/test-quality-verify` invoked | Review specified files/scope |
| During TDD cycle | Enforce before GREEN phase |

## The Iron Rule

Every test must answer YES to:

> "Would this test fail if a bug shipped to production?"

If no → reject the test. No exceptions.

## Strictly Forbidden Tests

| Type | Definition | Example |
|------|------------|---------|
| **Trivial** | Always true, cannot realistically fail | `assert 1 + 1 == 2` |
| **Shallow** | Touches surface, doesn't validate real logic | Testing getter returns what setter set |
| **Existence** | Only verifies something exists | `expect(user).toBeDefined()` |
| **Smoke-only** | Only checks "doesn't crash" | `expect(() => fn()).not.toThrow()` alone |
| **Implementation-coupled** | Depends on internals, not behavior | Asserting private field values |
| **Useless** | Passes even if business logic broken | Would pass with `return null` |

**The Useless Test Rule:** If the test would still pass after removing or breaking the core business logic → reject it.

## Valid Test Definition

A valid test must satisfy at least one:

- Verifies a business rule or domain invariant
- Detects incorrect behavior or wrong output
- Validates side effects or interactions with dependencies
- Ensures correct error handling or failure behavior
- Prevents regressions in logic

## Pre-Test Declaration (Mandatory)

Before writing ANY test:

```
BEHAVIOR: [what behavior is being validated]
BUG CAUGHT: [what real bug/regression this catches]
FAIL CHECK: [confirm test fails if logic is wrong]
```

If meaningful assertions cannot be written:
- Explain WHY a proper test is not possible
- Do NOT generate a fake or placeholder test

## Review Process

1. **Collect tests** - Identify test files/functions in scope
2. **Demand declaration** - What behavior? What bug caught? Would it fail?
3. **Check forbidden patterns** - Any instant-fail types?
4. **Verify validity** - Satisfies at least one valid test criterion?
5. **Verdict** - PASS or REJECT with specific reason

## Output Format

For each test:
```
---
Test: [test name/description]
File: [file:line]
Verdict: PASS | REJECT

# If REJECT:
Violation: [forbidden type or missing criterion]
Problem: [why this test is weak]
Evidence: [the code pattern that triggered rejection]
Rewrite Guidance: [what a valid test would look like]
---
```

After all tests:
```
## Summary
Total: N tests reviewed
Passed: X
Rejected: Y

## Systemic Issues
[Patterns across rejected tests]
```

## Language Examples

### JavaScript/TypeScript (Jest/Vitest)

```typescript
// REJECT: Existence test
test('user exists', () => {
  const user = createUser();
  expect(user).toBeDefined();  // Proves nothing
});

// PASS: Tests behavior, catches duplicate ID bug
test('createUser generates unique ID for each call', () => {
  // BEHAVIOR: Each user gets a unique identifier
  // BUG CAUGHT: ID generation returning static/duplicate values
  const user1 = createUser();
  const user2 = createUser();
  expect(user1.id).not.toBe(user2.id);
});
```

### Python (pytest)

```python
# REJECT: Smoke-only, happy path only
def test_divide():
    assert divide(10, 2) == 5  # Would pass with return 5

# PASS: Tests error handling edge case
def test_divide_by_zero_raises():
    # BEHAVIOR: Division by zero raises error
    # BUG CAUGHT: Missing zero-check causing crash/undefined
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)
```

### Go

```go
// REJECT: Implementation-coupled
func TestCache(t *testing.T) {
    c := NewCache()
    if c.items == nil { t.Fatal("items nil") }  // Tests internal
}

// PASS: Tests observable behavior
func TestCache_GetAfterSet(t *testing.T) {
    // BEHAVIOR: Cache returns previously stored values
    // BUG CAUGHT: Cache not persisting values correctly
    c := NewCache()
    c.Set("key", "value")
    got := c.Get("key")
    if got != "value" { t.Fatalf("got %q, want %q", got, "value") }
}
```

## Red Flags - Immediate Scrutiny

| Symptom | Likely Problem |
|---------|----------------|
| `toBeDefined()`, `!= nil`, `is not None` | Existence test |
| No assertions after setup | Test does nothing |
| Vague name ("works", "handles case") | Author doesn't know what it tests |
| 100% mocks, no real code | Testing the test, not the system |
| Only positive inputs | Edge cases ignored |
| Mirrors implementation step-by-step | Breaks on refactor, not on bugs |

## Reviewer Stance

- Never say "this test is fine" or "good enough"
- Assume every untested path will have a bug
- If you can't explain what bug it catches → reject it
- Coverage numbers mean nothing; only bug-catching ability matters
- Prioritize correctness, behavior, and regression safety

## Self-Check Before Approving

> "If I invert the core logic of the function under test, does this test fail?"

If no → the test is theater, not verification. Reject it.
