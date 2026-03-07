# Effective Go - Rules Reference

## Table of Contents
1. [Formatting](#formatting)
2. [Naming](#naming)
3. [Control Structures](#control-structures)
4. [Functions](#functions)
5. [Data Allocation](#data-allocation)
6. [Methods](#methods)
7. [Interfaces](#interfaces)
8. [Embedding](#embedding)
9. [Concurrency](#concurrency)
10. [Errors](#errors)

---

## Formatting

Use `gofmt` / `go fmt` for all formatting. No manual formatting decisions needed.

Key rules enforced by gofmt:
- Tabs for indentation
- No line length limit (but wrap sensibly)
- No parentheses on control structures
- Opening brace on same line as control structure

---

## Naming

### Package Names (M11)
- Lowercase, single-word names
- No underscores or mixedCaps
- Short, concise, evocative
- Package name provides context (avoid repetition)

```go
// Good - package name is context
bufio.Reader       // not bufio.BufReader
ring.New()         // not ring.NewRing
once.Do(setup)     // not once.DoOrWaitUntilDone

// Bad - redundant with package
bytes.ByteBuffer   // bytes.Buffer is sufficient
```

### Getters (M13)
No `Get` prefix on getters. Use `Set` prefix for setters.

```go
// Bad
func (o *Object) GetOwner() string { return o.owner }

// Good
func (o *Object) Owner() string { return o.owner }
func (o *Object) SetOwner(name string) { o.owner = name }
```

### Interface Names (M12)
One-method interfaces: method name + `-er` suffix.

```go
type Reader interface { Read(p []byte) (n int, err error) }
type Writer interface { Write(p []byte) (n int, err error) }
type Closer interface { Close() error }
type Stringer interface { String() string }
```

Use canonical names from standard library when applicable:
- `Read`, `Write`, `Close`, `Flush`, `String` have established signatures
- `String()` is the fmt.Stringer convention - don't use `ToString()`

### MixedCaps Convention (M11)
Always use `MixedCaps` or `mixedCaps`. Never underscores.

```go
// Good
var maxRetryCount int
type HTTPClient struct{}

// Bad
var max_retry_count int
type http_client struct{}
```

---

## Control Structures

### If Statement Patterns

```go
// Initialization form - preferred for error handling
if err := file.Chmod(0664); err != nil {
    return err
}

// Guard clause - avoid deep nesting (M02)
f, err := os.Open(name)
if err != nil {
    return err
}
d, err := f.Stat()
if err != nil {
    f.Close()
    return err
}
// use f and d
```

### For Loop Patterns

```go
// Range - prefer over index when possible
for key, value := range m {
    process(key, value)
}

// Blank identifier for unused variable
for _, value := range array {
    sum += value
}

// Parallel assignment
for i, j := 0, len(a)-1; i < j; i, j = i+1, j-1 {
    a[i], a[j] = a[j], a[i]
}
```

### Switch Patterns

```go
// Tagless switch (cleaner than if-else chains)
switch {
case '0' <= c && c <= '9':
    return c - '0'
case 'a' <= c && c <= 'f':
    return c - 'a' + 10
}

// Comma-separated cases
switch c {
case ' ', '?', '&', '=', '#', '+', '%':
    return true
}

// Type switch
switch v := value.(type) {
case string:
    return v
case int:
    return strconv.Itoa(v)
default:
    return fmt.Sprintf("%v", v)
}
```

---

## Functions

### Multiple Return Values

```go
// Standard error pattern
func (file *File) Write(b []byte) (n int, err error)

// Named returns for documentation (M10)
func ReadFull(r Reader, buf []byte) (n int, err error) {
    for len(buf) > 0 && err == nil {
        var nr int
        nr, err = r.Read(buf)
        n += nr
        buf = buf[nr:]
    }
    return
}
```

### Defer (H04)

```go
// Resource cleanup
func Contents(filename string) (string, error) {
    f, err := os.Open(filename)
    if err != nil {
        return "", err
    }
    defer f.Close()
    // ... use f ...
}

// LIFO order
for i := 0; i < 5; i++ {
    defer fmt.Printf("%d ", i)  // prints: 4 3 2 1 0
}

// Arguments evaluated immediately
defer fmt.Printf("value: %d\n", expensiveCall())
// expensiveCall() runs NOW, Printf runs at function exit
```

---

## Data Allocation

### new vs make

```go
// new(T) - allocates zeroed storage, returns *T
p := new(SyncedBuffer)  // ready to use (zero values are useful)

// make(T, args) - initializes slices, maps, channels
s := make([]int, 10, 100)     // slice
m := make(map[string]int)     // map
c := make(chan int)            // channel
```

### Composite Literals

```go
// Always use field names (M04)
return &File{fd: fd, name: name}

// Array/slice literals
a := []string{"no error", "Eio", "invalid argument"}

// Map literals
m := map[string]int{
    "UTC":  0,
    "EST": -5 * 60 * 60,
}
```

### Slices vs Arrays

Prefer slices over arrays. Arrays are values (copied on assignment); slices are references.

```go
// Use slices
data := make([]byte, 1024)

// Use arrays only when size is fixed and part of the type contract
type Matrix [4][4]float64
```

### Append

```go
x := []int{1, 2, 3}
x = append(x, 4, 5, 6)

// Append slice to slice
y := []int{4, 5, 6}
x = append(x, y...)
```

---

## Methods

### Pointer vs Value Receiver

```go
// Value receiver - doesn't modify receiver, safe to copy
func (p Point) Distance(q Point) float64 { ... }

// Pointer receiver - modifies receiver or receiver is large
func (p *Point) ScaleBy(factor float64) {
    p.X *= factor
    p.Y *= factor
}
```

Rules of thumb:
- If method modifies receiver → pointer receiver
- If receiver is large struct → pointer receiver for efficiency
- If any method has pointer receiver → all methods should use pointer receiver (consistency)
- Value receivers are safe for concurrent use

---

## Interfaces

### Design Principles

```go
// Accept interfaces, return structs
func Process(r io.Reader) (*Result, error) { ... }

// Small interfaces are better
type Reader interface {
    Read(p []byte) (n int, err error)
}

// Compose small interfaces
type ReadWriter interface {
    Reader
    Writer
}
```

### Export interfaces, not implementations

```go
// Good - callers depend on interface
func NewHasher() hash.Hash32 {
    return crc32.NewIEEE()
}

// This allows switching implementation without breaking callers
```

---

## Embedding

```go
// Interface embedding - compose capabilities
type ReadWriter interface {
    Reader
    Writer
}

// Struct embedding - delegation, not inheritance
type Job struct {
    Command string
    *log.Logger
}

// Promoted methods
job := &Job{"cmd", log.New(os.Stderr, "Job: ", log.Ldate)}
job.Println("starting...")  // log.Logger method promoted

// Access embedded field by type name
job.Logger.Printf("custom format")
```

---

## Concurrency

### Share by Communicating
"Do not communicate by sharing memory; instead, share memory by communicating."

```go
// Preferred - channel-based coordination
result := make(chan int)
go func() {
    result <- compute()
}()
value := <-result

// Use mutex only for simple state protection
var mu sync.Mutex
var count int
mu.Lock()
count++
mu.Unlock()
```

### Goroutine Patterns

```go
// Fixed worker pool (preferred)
func Serve(queue chan *Request) {
    for i := 0; i < MaxWorkers; i++ {
        go func() {
            for req := range queue {
                process(req)
            }
        }()
    }
}

// Semaphore pattern with buffered channel
var sem = make(chan struct{}, MaxConcurrent)
func handle(r *Request) {
    sem <- struct{}{}        // acquire
    defer func() { <-sem }() // release
    process(r)
}
```

### Channel Patterns

```go
// Signal completion
done := make(chan struct{})
go func() {
    defer close(done)
    work()
}()
<-done  // wait

// Fan-out, fan-in
func fanOut(input <-chan int, workers int) <-chan int {
    results := make(chan int)
    var wg sync.WaitGroup
    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for v := range input {
                results <- process(v)
            }
        }()
    }
    go func() {
        wg.Wait()
        close(results)
    }()
    return results
}
```

---

## Errors

### Error Interface

```go
// Custom error type with context
type PathError struct {
    Op   string
    Path string
    Err  error
}

func (e *PathError) Error() string {
    return e.Op + " " + e.Path + ": " + e.Err.Error()
}

func (e *PathError) Unwrap() error {
    return e.Err
}
```

### Panic and Recover

```go
// Panic only for truly unrecoverable situations
// Never in library code - return errors instead

// Recover in server code to prevent one request from killing server
func safeHandler(w http.ResponseWriter, r *http.Request) {
    defer func() {
        if err := recover(); err != nil {
            log.Printf("panic: %v", err)
            http.Error(w, "Internal Server Error", 500)
        }
    }()
    handle(w, r)
}
```
