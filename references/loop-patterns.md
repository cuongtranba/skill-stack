# Loop Patterns Reference

## Until Loop (Exit When True)

Exit when condition becomes true.

```yaml
- loop:
    name: retry-until-success
    until: "{{ operation_succeeded }}"
    max_iterations: 5
    steps:
      - name: try-operation
        type: bash
        run: ./do-something.sh
        outputs: [operation_succeeded]
```

---

## While Loop (Continue While True)

Continue while condition is true.

```yaml
- loop:
    name: process-while-items
    while: "{{ has_more_items }}"
    steps:
      - name: process-item
        type: bash
        run: ./process-next.sh
        outputs: [has_more_items]
```

---

## Fixed Iterations

Run exactly N times.

```yaml
- loop:
    name: retry-3-times
    times: 3
    steps:
      - name: attempt
        type: bash
        run: ./attempt.sh
```

---

## For-Each Loop

Iterate over a list.

```yaml
- loop:
    name: process-files
    for_each: "{{ changed_files }}"
    as: current_file
    steps:
      - name: lint-file
        type: bash
        run: eslint {{ current_file }}
      - name: test-file
        type: bash
        run: jest {{ current_file }}
```

---

## Safety Limits

Always set `max_iterations` to prevent infinite loops:

```yaml
- loop:
    name: safe-loop
    until: "{{ done }}"
    max_iterations: 20
    on_max_reached: ask  # ask | stop | continue
    steps:
      - ...
```

---

## Nested Loops

Loops can contain other loops (up to 3 levels):

```yaml
- loop:
    name: outer
    times: 3
    steps:
      - loop:
          name: inner
          times: 2
          steps:
            - name: work
              type: bash
              run: echo "Outer $OUTER, Inner $INNER"
```
