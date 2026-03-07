# Go Generics Guide - When to Use and When Not To

Source: https://go.dev/blog/when-generics

## Core Principle

**Write code first, not types.** Start by writing functions; add type parameters later when their usefulness is clear.

---

## When TO Use Generics

### 1. Operations on Slices, Maps, Channels (H11)

Use type parameters when writing functions that operate generically on built-in container types.

```go
// Good - generic map key extraction
func MapKeys[Key comparable, Val any](m map[Key]Val) []Key {
    s := make([]Key, 0, len(m))
    for k := range m {
        s = append(s, k)
    }
    return s
}

// Good - generic filter
func Filter[T any](s []T, fn func(T) bool) []T {
    var result []T
    for _, v := range s {
        if fn(v) {
            result = append(result, v)
        }
    }
    return result
}

// Good - generic contains
func Contains[T comparable](s []T, target T) bool {
    for _, v := range s {
        if v == target {
            return true
        }
    }
    return false
}
```

### 2. General-Purpose Data Structures

Use type parameters for data structures not built into the language (trees, linked lists, queues, sets).

```go
// Good - generic binary tree
type Tree[T any] struct {
    cmp  func(T, T) int
    root *node[T]
}

type node[T any] struct {
    left, right *node[T]
    val         T
}

// Good - generic set
type Set[T comparable] struct {
    m map[T]struct{}
}

func NewSet[T comparable]() *Set[T] {
    return &Set[T]{m: make(map[T]struct{})}
}

func (s *Set[T]) Add(v T)          { s.m[v] = struct{}{} }
func (s *Set[T]) Contains(v T) bool { _, ok := s.m[v]; return ok }
func (s *Set[T]) Remove(v T)       { delete(s.m, v) }
```

### 3. Methods Identical Across Types

When different types need the exact same method implementation, use type parameters.

```go
// Good - identical sort scaffolding for any slice
type SliceFn[T any] struct {
    s    []T
    less func(T, T) bool
}

func (s SliceFn[T]) Len() int           { return len(s.s) }
func (s SliceFn[T]) Swap(i, j int)      { s.s[i], s.s[j] = s.s[j], s.s[i] }
func (s SliceFn[T]) Less(i, j int) bool { return s.less(s.s[i], s.s[j]) }
```

### 4. Eliminating Exact Code Duplication

If you find yourself writing the **exact same code** multiple times with only the types changing, that's a strong signal for generics.

---

## When NOT To Use Generics

### 1. Don't Replace Interface Types with Type Parameters (H12)

If you just need to call methods on a value, use an interface.

```go
// Bad - unnecessary type parameter
func ReadSome[T io.Reader](r T) ([]byte, error) {
    buf := make([]byte, 1024)
    n, err := r.Read(buf)
    return buf[:n], err
}

// Good - simple interface parameter
func ReadSome(r io.Reader) ([]byte, error) {
    buf := make([]byte, 1024)
    n, err := r.Read(buf)
    return buf[:n], err
}
```

Why: No performance advantage, harder to read, no additional type safety.

### 2. Don't Use When Method Implementations Differ

If each type requires a different method body, use interfaces.

```go
// Different types read differently:
// - File reads from disk
// - Buffer reads from memory
// - Network reads from socket
// These need DIFFERENT implementations → use io.Reader interface

// Same implementation for all types:
// - Len() for any slice is always len(s)
// - Swap() for any slice is always s[i], s[j] = s[j], s[i]
// → use type parameters
```

### 3. Use Reflection When Types Lack Methods

When you need to support types that don't have methods (like encoding arbitrary structs to JSON), and the operation varies per type, use reflection.

```go
// encoding/json needs to handle ANY struct
// Can't require MarshalJSON method (some types won't have it)
// Encoding a struct ≠ encoding a slice (different logic)
// → reflection is the right tool
```

---

## Decision Summary

| Scenario | Use |
|----------|-----|
| Generic operations on slices/maps/channels | Type parameters |
| Reusable data structures (tree, set, queue) | Type parameters |
| Identical method implementations across types | Type parameters |
| Eliminating exact code duplication | Type parameters |
| Calling methods on a value | Interface types |
| Different implementations per type | Interface types |
| Supporting method-less types with varying logic | Reflection |

---

## Best Practice: Prefer Functions Over Methods on Generic Types

```go
// Preferred - function parameter
type Tree[T any] struct {
    cmp func(T, T) int  // comparison as function
}

// Less preferred - requires method on T
type Comparable interface {
    CompareTo(other Comparable) int
}
type Tree[T Comparable] struct{}
```

Advantage: Users can pass any type + a comparison function, without needing to define methods.

---

## Constraint Patterns

```go
// Built-in constraints
func Sum[T int | float64](s []T) T { ... }

// Named constraint
type Number interface {
    int | int8 | int16 | int32 | int64 |
    float32 | float64
}

// Comparable constraint (supports == and !=)
func Contains[T comparable](s []T, v T) bool { ... }

// Ordered constraint (supports < > <= >=)
// Use golang.org/x/exp/constraints or cmp.Ordered
func Max[T cmp.Ordered](a, b T) T {
    if a > b {
        return a
    }
    return b
}
```
