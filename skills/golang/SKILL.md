---
name: golang
description: Invoke for any Go/Golang programming work. Triggers: mentions of "Go" (the language), "Golang", `.go` file paths (e.g. `parser.go`, `main.go`, `upload.go`), `go.mod`, `go.sum`, `go build`, `go test`, `go vet`, goroutines, channels, structs, interfaces, or Go generics. Also triggers on slash commands starting with `/go:` such as `/go:audit`, `/go:fix`, `/go:fix P0`, `/go:verify`. Covers writing new Go code, debugging Go errors, reviewing or refactoring Go files, writing Go tests, building Go APIs/services, and migrating other languages to Go. Enforces Uber Go Style Guide and idiomatic patterns.
---

# Go Best Practices Skill

Enforce idiomatic Go patterns from Uber Go Style Guide, Effective Go, and Go generics guidelines. This skill validates generated code, audits existing code, and suggests fixes categorized by priority.

## Commands

| Command | Purpose |
|---------|---------|
| `/go:audit` | Scan Go files for violations, show results in priority table |
| `/go:fix` | Auto-fix detected issues from the last audit |
| `/go:verify` | Verify code passes all checks after changes |

## Triggering

This skill activates when:
- Working with `.go` files or `go.mod`/`go.sum`
- Generating, reviewing, or modifying Go code
- Running Go commands (`go build`, `go test`, `go vet`)
- User invokes `/go:audit`, `/go:fix`, or `/go:verify`

## Code Generation Checklist

When generating or modifying Go code, proactively apply these patterns. These are the things that separate production-grade Go from "works but not idiomatic" Go. Apply them automatically — don't wait for an audit to catch them.

### Architecture (apply to any new file/package)
- [ ] **Dependency injection** — no package-level mutable state. Wrap state in a struct with a constructor (`NewXxx`)
- [ ] **Compile-time interface check** — for any type implementing an interface, add `var _ InterfaceName = (*TypeName)(nil)`
- [ ] **Accept interfaces, return structs** — function params should be interfaces when possible, return concrete types

### Error Handling (apply to every function)
- [ ] **Wrap errors with context** — `fmt.Errorf("operation %s: %w", name, err)`, NEVER bare `return err`. Hard rule. After writing any function, grep your own output for `return err` — every match must be wrapped or justified. Wrap with: (a) operation name, (b) identifying key (id, name, iban, row index, etc.), (c) `%w` verb. Bare `return err` discards trace context and breaks debuggability.
- [ ] **Refactor extraction trap** — when splitting a function (e.g. for cognitive-complexity gate), audit error returns in BOTH new helpers AND new call sites. Extraction frequently introduces 5–10 bare `return err` that all need wrapping.
- [ ] **Sentinel errors** for expected conditions — `var ErrNotFound = errors.New("not found")` with `Err` prefix
- [ ] **Error types** for actionable errors — `type ValidationError struct{...}` with `Error` suffix
- [ ] **Handle once** — either log OR return, never both

### Structs (apply to every struct)
- [ ] **JSON tags** on all fields of marshaled structs — `json:"field_name"`
- [ ] **Named fields** in initialization — `User{Name: "x"}` not `User{"x"}`
- [ ] **`_` prefix** on unexported package-level vars — `var _defaultTimeout = 30 * time.Second`
- [ ] **Named mutex field** — `mu sync.Mutex` not embedded `sync.Mutex`

### Functions (apply to every function)
- [ ] **Guard clauses** — handle error first, return early, keep happy path un-indented
- [ ] **`defer`** for cleanup — mutex unlock, file close, connection close
- [ ] **`time.Duration`** for time params — never `int` seconds or `float64` milliseconds
- [ ] **No `Get` prefix** on getters — `Owner()` not `GetOwner()`

### Concurrency (apply when using goroutines)
- [ ] **Track goroutine lifecycle** — `sync.WaitGroup` or stop channel, never fire-and-forget
- [ ] **Copy slices/maps at boundaries** — defensive copy before storing or returning
- [ ] **Functional options** for constructors with >2 optional params

### Tests (apply when writing tests)
- [ ] **Table-driven tests** — `tests := []struct{...}` with `t.Run`
- [ ] **Meaningful test names** — describe the scenario, not the function

## Post-Generation Validation

After generating or modifying any Go code, validate against the checklist above and the rules below. If violations are found, fix them before presenting the final code. Do NOT present code with known violations.

## Rule Categories

Rules are organized by priority. For full details with code examples, read the corresponding reference file.

### P0 - Critical (must fix immediately)

These cause bugs, data races, or security issues:

| ID | Rule | Source |
|----|------|--------|
| C01 | Handle all errors - never ignore error returns in business logic. `_, _ =` is acceptable only for best-effort fallback writes (e.g., writing a fallback error response when the primary path already failed) | Uber/Effective |
| C02 | Handle type assertion failures with comma-ok pattern | Uber |
| C03 | Copy slices/maps at API boundaries to prevent data races | Uber |
| C04 | Don't fire-and-forget goroutines - always track lifecycle | Uber |
| C05 | Use `sync.Mutex` correctly - don't embed in exported structs | Uber |
| C06 | Don't panic in library code - return errors instead | Uber/Effective |
| C07 | No `interface{}`/`any` for data types - use concrete types or type parameters. Note: `any` as a generic constraint (e.g., `[V any]`) is correct Go — only flag `any`/`interface{}` when used as a concrete value type | CLAUDE.md |
| C09 | Avoid mutable globals - use dependency injection | Uber |
| C10 | Wait for goroutines to exit - use sync.WaitGroup or channels | Uber |

### P1 - High (fix before commit)

These cause maintenance debt or subtle bugs:

| ID | Rule | Source |
|----|------|--------|
| H01 | Verify interface compliance at compile time with `var _ I = (*T)(nil)` | Uber |
| H02 | Wrap errors with context using `fmt.Errorf("...: %w", err)` | Uber |
| H03 | Handle errors once - don't log AND return | Uber |
| H04 | Use `defer` for cleanup (files, locks, connections) | Uber/Effective |
| H05 | Channel size is one or none - justify buffered channels | Uber |
| H06 | Start enums at one (reserve zero for unknown/invalid) | Uber |
| H07 | Use `time.Time` and `time.Duration` - not int/float for time | Uber |
| H08 | Use field tags in marshaled structs (`json`, `yaml`) | Uber |
| H09 | Avoid `init()` - prefer explicit initialization | Uber |
| H10 | Exit only in `main()` - never in library packages | Uber |
| H11 | Use generics for container operations (slices, maps, channels) | Generics |
| H12 | Don't use generics when interface types suffice | Generics |
| H13 | No goroutines in `init()` | Uber |

### P2 - Medium (fix in current PR)

Style and readability issues:

| ID | Rule | Source |
|----|------|--------|
| M01 | Group imports: stdlib, external, internal (separated by blank line) | Uber |
| M02 | Reduce nesting - handle errors first, return early | Uber/Effective |
| M03 | Remove unnecessary `else` - especially after return/break/continue | Uber |
| M04 | Use field names when initializing structs | Uber |
| M05 | Omit zero-value fields in struct initialization | Uber |
| M06 | Use `var` for zero-value structs instead of `T{}` | Uber |
| M07 | Prefix unexported package-level vars with `_` | Uber |
| M08 | Avoid naked parameters - use comments or named types | Uber |
| M09 | Use raw string literals to avoid escaping | Uber |
| M10 | Name result parameters in exported functions for documentation | Effective |
| M11 | Use `MixedCaps`/`mixedCaps` naming - never underscores | Effective |
| M12 | One-method interfaces: name = method + `-er` suffix | Effective |
| M13 | No `Get` prefix on getters | Effective |
| M14 | Use table-driven tests | Uber |
| M15 | Use functional options pattern for complex constructors | Uber |
| M16 | Reduce variable scope - declare close to first use | Uber |
| M17 | Avoid overly long lines (guideline: ~99 chars) | Uber |

### P3 - Low (nice to have)

Performance and polish:

| ID | Rule | Source |
|----|------|--------|
| L01 | Prefer `strconv` over `fmt` for string conversions | Uber |
| L02 | Avoid repeated string-to-byte conversions | Uber |
| L03 | Specify container capacity with `make([]T, 0, n)` | Uber |
| L04 | Use `nil` slice (not empty slice) as default | Uber |
| L05 | Format strings outside Printf for reuse | Uber |
| L06 | Prefer functions over methods on generic types | Generics |
| L07 | Be consistent with existing codebase style | Uber |
| L08 | Group similar declarations | Uber |
| L09 | Order functions: exported first, then by call order | Uber |

## /go:audit Command

When user invokes `/go:audit` (or when auditing is requested):

### Step 1: Discover scope

Determine what to audit:
- If user specifies files/packages, use those
- Otherwise, find all `.go` files in the current working directory (recursively)
- Exclude `vendor/`, `_test.go` (unless explicitly included), generated files

### Step 2: Read and analyze

Read each Go file and check against ALL rules (P0-P3). For each violation found, record:
- File path and line number
- Rule ID and description
- Current code snippet (the problematic line/block)
- Suggested fix (the corrected code)

### Step 3: Present results

Display findings in a markdown table grouped by priority:

```
## Go Audit Results

**Files scanned:** N | **Issues found:** N | **Critical:** N | **High:** N | **Medium:** N | **Low:** N

### P0 - Critical

| # | Rule | File:Line | Issue | Current Code | Suggested Fix |
|---|------|-----------|-------|--------------|---------------|
| 1 | C01  | pkg/api/handler.go:42 | Error ignored | `json.Unmarshal(data, &v)` | `if err := json.Unmarshal(data, &v); err != nil { return fmt.Errorf("unmarshal: %w", err) }` |

### P1 - High
...

### P2 - Medium
...

### P3 - Low
...
```

If no issues found at a priority level, show "No issues found" for that level.

### Step 4: Summary and recommendations

After the table, provide:
- Total issue count by priority
- Top 3 most common patterns to fix
- Suggested order of fixes (always P0 first)

## /go:fix Command

When user invokes `/go:fix`:

1. If a previous audit exists in conversation, use those findings
2. If no audit exists, run `/go:audit` first
3. Apply fixes in priority order (P0 first, then P1, etc.)
4. For each fix:
   - Show the before/after diff
   - Apply the change using the Edit tool
5. After all fixes, run `/go:verify` automatically

The user can also specify scope:
- `/go:fix P0` - fix only critical issues
- `/go:fix C01` - fix only a specific rule
- `/go:fix pkg/api/` - fix only files in a directory

## /go:verify Command

When user invokes `/go:verify`:

1. **Static checks** - Read modified files and verify all rules pass
2. **Tool checks** - If available, run through project task runner:
   - `go vet ./...`
   - `go build ./...`
   - `golangci-lint run` (if configured)
3. **Results** - Present verification status:

```
## Go Verify Results

| Check | Status | Details |
|-------|--------|---------|
| P0 Rules | PASS | No critical violations |
| P1 Rules | PASS | No high-priority violations |
| P2 Rules | 2 remaining | M01 (imports), M03 (unnecessary else) |
| go vet | PASS | |
| go build | PASS | |
| golangci-lint | N/A | Not configured |
```

## Key Patterns Reference

When you need detailed code examples for any rule, read the appropriate reference file:

- `references/uber-style-rules.md` - Uber Go Style Guide rules with bad/good examples
- `references/effective-go-rules.md` - Effective Go idioms and patterns
- `references/generics-guide.md` - When to use/avoid generics

## Generics Decision Tree

When deciding whether to use generics:

```
Is the code operating on slices/maps/channels generically?
  YES → Use type parameters
  NO ↓
Is it a general-purpose data structure (tree, list, queue)?
  YES → Use type parameters
  NO ↓
Are you writing identical methods for multiple types?
  YES → Use type parameters
  NO ↓
Do you just need to call methods on the value?
  YES → Use interface types instead
  NO ↓
Do different types need different implementations?
  YES → Use interface types instead
  NO ↓
Must you support types without methods?
  YES → Consider reflection
  NO → Use interface types
```

## Error Handling Patterns

Preferred error handling (from most to least idiomatic):

```go
// 1. Sentinel errors for expected conditions
var ErrNotFound = errors.New("not found")

// 2. Error types for actionable errors (callers need details)
type ValidationError struct {
    Field   string
    Message string
}
func (e *ValidationError) Error() string { ... }

// 3. Error wrapping for context
return fmt.Errorf("parse config %s: %w", path, err)

// 4. Inline errors for one-off situations
return errors.New("unexpected empty input")
```

Error naming:
- Sentinel: `Err` prefix → `ErrNotFound`, `ErrTimeout`
- Types: `Error` suffix → `ValidationError`, `NotFoundError`
- Wrapping: include operation context → `"read config: %w"`

## HTTP Patterns

```go
// writeJSON helper — use `any` as parameter type here because json.Marshal
// accepts any type. This is a boundary function, not business logic.
func writeJSON(w http.ResponseWriter, status int, v any) {
    w.Header().Set("Content-Type", "application/json")
    data, err := json.Marshal(v)
    if err != nil {
        w.WriteHeader(http.StatusInternalServerError)
        // Best-effort fallback — _, _ is acceptable here
        _, _ = w.Write([]byte(`{"error":"internal server error"}`))
        return
    }
    w.WriteHeader(status)
    if _, err := w.Write(data); err != nil {
        log.Printf("write response: %v", err)
    }
}

// Handler struct with dependency injection (not package-level globals)
type UserHandler struct {
    Store *UserStore
}
var _ http.Handler = (*UserHandler)(nil)  // compile-time check

func (h *UserHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        writeJSON(w, http.StatusMethodNotAllowed, ErrorResponse{Error: "method not allowed"})
        return  // guard clause
    }
    // ... decode, validate, store, respond
}
```

## Concurrency Patterns

```go
// Worker pool (preferred over unbounded goroutines)
func process(items []Item) {
    sem := make(chan struct{}, runtime.NumCPU())
    var wg sync.WaitGroup
    for _, item := range items {
        wg.Add(1)
        sem <- struct{}{}
        go func(it Item) {
            defer wg.Done()
            defer func() { <-sem }()
            handle(it)
        }(item)
    }
    wg.Wait()
}

// Channel-based result collection
func fetch(urls []string) []Result {
    results := make(chan Result, len(urls))
    var wg sync.WaitGroup
    for _, url := range urls {
        wg.Add(1)
        go func(u string) {
            defer wg.Done()
            results <- doFetch(u)
        }(url)
    }
    go func() {
        wg.Wait()
        close(results)
    }()

    var out []Result
    for r := range results {
        out = append(out, r)
    }
    return out
}
```
