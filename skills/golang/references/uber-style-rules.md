# Uber Go Style Guide - Complete Rules Reference

## Table of Contents
1. [Guidelines](#guidelines)
2. [Performance](#performance)
3. [Style](#style)
4. [Patterns](#patterns)

---

## Guidelines

### Pointers to Interfaces
Never use pointer to interface. Pass interfaces as values.

```go
// Bad
func process(r *io.Reader) { ... }

// Good
func process(r io.Reader) { ... }
```

### Verify Interface Compliance (H01)
Use compile-time checks:

```go
// Pointer receiver
var _ http.Handler = (*Handler)(nil)

// Value receiver
var _ http.Handler = LogHandler{}
```

### Zero-value Mutexes are Valid (C05)
Don't embed mutex in exported structs:

```go
// Bad - Lock/Unlock exposed in API
type SMap struct {
    sync.Mutex
    data map[string]string
}

// Good - mutex is implementation detail
type SMap struct {
    mu   sync.Mutex
    data map[string]string
}
```

### Copy Slices and Maps at Boundaries (C03)

```go
// Bad - caller can modify internal state
func (d *Driver) SetTrips(trips []Trip) {
    d.trips = trips
}

// Good - defensive copy
func (d *Driver) SetTrips(trips []Trip) {
    d.trips = make([]Trip, len(trips))
    copy(d.trips, trips)
}

// Bad - returning internal reference
func (s *Stats) Snapshot() map[string]int {
    return s.counters
}

// Good - return copy
func (s *Stats) Snapshot() map[string]int {
    result := make(map[string]int, len(s.counters))
    for k, v := range s.counters {
        result[k] = v
    }
    return result
}
```

### Defer to Clean Up (H04)

```go
// Bad - easy to miss unlock on multiple returns
p.Lock()
if p.count < 10 {
    p.Unlock()
    return p.count
}
p.count++
newCount := p.count
p.Unlock()
return newCount

// Good
p.Lock()
defer p.Unlock()
if p.count < 10 {
    return p.count
}
p.count++
return p.count
```

### Channel Size is One or None (H05)

```go
// Bad - arbitrary buffer size
c := make(chan int, 64)

// Good - unbuffered (synchronous)
c := make(chan int)

// Good - buffered size 1 (for single signal)
c := make(chan int, 1)

// Good - documented why buffer needed
// Buffered to MaxOutstanding to avoid blocking senders
c := make(chan int, MaxOutstanding)
```

### Start Enums at One (H06)

```go
// Bad - zero value is valid state
type Operation int
const (
    Add Operation = iota  // Add = 0
    Subtract
    Multiply
)

// Good - zero value is invalid/unknown
type Operation int
const (
    _        Operation = iota  // skip zero
    Add                        // Add = 1
    Subtract
    Multiply
)
```

### Use time Package (H07)

```go
// Bad
func poll(delay int) { ... }       // seconds? milliseconds?
poll(10)

// Good
func poll(delay time.Duration) { ... }
poll(10 * time.Second)

// Bad - manual time math
func isActive(now, start, stop int) bool {
    return start <= now && now < stop
}

// Good
func isActive(now, start, stop time.Time) bool {
    return (now.After(start) || now.Equal(start)) && now.Before(stop)
}
```

### Error Types (C01, H02, H03)

```go
// Error wrapping with context
// Bad
return err

// Good
return fmt.Errorf("new store: %w", err)

// Error naming
// Sentinel errors: Err prefix
var ErrNotFound = errors.New("not found")
var (
    ErrBrokenLink = errors.New("broken link")
    ErrNotAllowed = errors.New("not allowed")
)

// Error types: Error suffix
type NotFoundError struct {
    Name string
}
func (e *NotFoundError) Error() string {
    return e.Name + ": not found"
}

// Handle errors once - don't log AND return
// Bad
func do() error {
    err := process()
    if err != nil {
        log.Printf("process failed: %v", err)  // logged here
        return err                                // and returned
    }
    return nil
}

// Good - return with context
func do() error {
    if err := process(); err != nil {
        return fmt.Errorf("process: %w", err)
    }
    return nil
}

// Good - log at top level only
func main() {
    if err := do(); err != nil {
        log.Printf("failed: %v", err)
        os.Exit(1)
    }
}
```

### Handle Type Assertion Failures (C02)

```go
// Bad - panics on wrong type
t := i.(string)

// Good - comma-ok pattern
t, ok := i.(string)
if !ok {
    // handle the error
}
```

### Don't Panic (C06)

```go
// Bad - panics in library code
func Foo(bar string) {
    if len(bar) == 0 {
        panic("bar must not be empty")
    }
}

// Good - return error
func Foo(bar string) error {
    if len(bar) == 0 {
        return errors.New("bar must not be empty")
    }
    return nil
}
```

### Avoid Mutable Globals (C09)

```go
// Bad
var db *sql.DB
func init() {
    db, _ = sql.Open("driver", "dsn")
}

// Good - dependency injection
type App struct {
    db *sql.DB
}
func NewApp(db *sql.DB) *App {
    return &App{db: db}
}
```

### Avoid Embedding Types in Public Structs

```go
// Bad - exposes AbstractList methods
type ConcreteList struct {
    *AbstractList
}

// Good - delegates explicitly
type ConcreteList struct {
    list *AbstractList
}
func (l *ConcreteList) Add(e Entity) {
    l.list.Add(e)
}
```

### Avoid Using Built-In Names

Never shadow: `error`, `string`, `int`, `len`, `cap`, `append`, `copy`, `delete`, `make`, `new`, `close`, `panic`, `recover`, etc.

```go
// Bad
var error string
var string int
copy := func() {}

// Good
var errorMessage string
var count int
copyFunc := func() {}
```

### Avoid init() (H09)

```go
// Bad
var _defaultPort = 8080
func init() {
    if p := os.Getenv("PORT"); p != "" {
        _defaultPort, _ = strconv.Atoi(p)
    }
}

// Good
var _defaultPort = getPort()
func getPort() int {
    if p := os.Getenv("PORT"); p != "" {
        if port, err := strconv.Atoi(p); err == nil {
            return port
        }
    }
    return 8080
}
```

### Exit in Main (H10)

```go
// Bad - exit in library
func run() {
    if err := process(); err != nil {
        log.Fatal(err)  // calls os.Exit(1)
    }
}

// Good - return error, let main decide
func run() error {
    return process()
}

func main() {
    if err := run(); err != nil {
        log.Fatal(err)
    }
}
```

### Use Field Tags in Marshaled Structs (H08)

```go
// Bad - relies on field name
type Stock struct {
    Price int
    Name  string
}

// Good - explicit tags
type Stock struct {
    Price int    `json:"price"`
    Name  string `json:"name"`
}
```

### Don't Fire-and-Forget Goroutines (C04, C10)

```go
// Bad - no lifecycle management
go func() {
    for {
        flush()
        time.Sleep(delay)
    }
}()

// Good - tracked with WaitGroup and stop channel
var (
    stop = make(chan struct{})
    done = make(chan struct{})
)
go func() {
    defer close(done)
    ticker := time.NewTicker(delay)
    defer ticker.Stop()
    for {
        select {
        case <-ticker.C:
            flush()
        case <-stop:
            return
        }
    }
}()

// To stop:
close(stop)
<-done
```

---

## Performance

### Prefer strconv over fmt (L01)

```go
// Bad
s := fmt.Sprint(42)

// Good
s := strconv.Itoa(42)
```

### Avoid Repeated String-to-Byte Conversions (L02)

```go
// Bad
for i := 0; i < b.N; i++ {
    w.Write([]byte("Hello world"))
}

// Good
data := []byte("Hello world")
for i := 0; i < b.N; i++ {
    w.Write(data)
}
```

### Specify Container Capacity (L03)

```go
// Bad
m := make(map[string]os.FileInfo)
files, _ := os.ReadDir("./files")
for _, f := range files {
    m[f.Name()] = f
}

// Good - preallocate
files, _ := os.ReadDir("./files")
m := make(map[string]os.FileInfo, len(files))
for _, f := range files {
    m[f.Name()] = f
}
```

---

## Style

### Import Group Ordering (M01)

```go
import (
    "fmt"           // stdlib
    "os"

    "go.uber.org/atomic"     // external
    "golang.org/x/sync"

    "github.com/myorg/myproject/internal"  // internal
)
```

### Reduce Nesting (M02)

```go
// Bad
if err != nil {
    // ...
} else {
    // normal path (deeply nested)
}

// Good - guard clause
if err != nil {
    return err
}
// normal path (no nesting)
```

### Unnecessary Else (M03)

```go
// Bad
if a {
    b = true
} else {
    b = false
}

// Good
b = a

// Bad
var a int
if b {
    a = 100
} else {
    a = 10
}

// Good
a := 10
if b {
    a = 100
}
```

### Struct Initialization (M04, M05, M06)

```go
// Bad - positional
k := User{"John", "Doe", true}

// Good - named fields (M04)
k := User{
    FirstName: "John",
    LastName:  "Doe",
    Admin:     true,
}

// Good - omit zero fields (M05)
k := User{
    FirstName: "John",
    LastName:  "Doe",
}

// Good - use var for zero struct (M06)
var k User
```

### Naked Parameters (M08)

```go
// Bad - what do true, false mean?
printInfo("foo", true, false)

// Good - use named types or comments
printInfo("foo", true /* isLocal */, false /* done */)

// Better - use types
type Region int
const (
    UnknownRegion Region = iota
    Local
)
printInfo("foo", Local)
```

### Table-Driven Tests (M14)

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
        {"zero", 0, 0, 0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d, want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

### Functional Options (M15)

```go
type Option func(*Server)

func WithPort(port int) Option {
    return func(s *Server) {
        s.port = port
    }
}

func WithTimeout(timeout time.Duration) Option {
    return func(s *Server) {
        s.timeout = timeout
    }
}

func NewServer(opts ...Option) *Server {
    s := &Server{
        port:    8080,
        timeout: 30 * time.Second,
    }
    for _, o := range opts {
        o(s)
    }
    return s
}

// Usage
srv := NewServer(
    WithPort(9090),
    WithTimeout(60 * time.Second),
)
```

### Local Variable Declarations

```go
// Use := for short variable declarations
s := "hello"

// Use var when zero value matters
var s string  // intentionally empty

// Use var for type that doesn't match literal
var _statusTemplate = template.Must(template.New("status").Parse(`...`))
```

### Nil Slice (L04)

```go
// Bad
if len(s) == 0 { ... }  // works but not idiomatic for init

// Good - nil is valid slice
var s []int              // nil slice, len=0, cap=0, json: null
s = []int{}              // empty slice, len=0, cap=0, json: []
// Use nil slice as default, empty slice only when JSON [] needed
```
