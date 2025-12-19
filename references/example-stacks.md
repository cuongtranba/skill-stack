# Example Stack Patterns

These examples show what's possible. Use `/stack build` to create your own.

## Simple Sequential

```yaml
name: quick-task
description: Simple linear workflow
steps:
  - name: plan
    type: skill
    ref: superpowers:brainstorming
    transition: prompt

  - name: implement
    type: skill
    ref: superpowers:test-driven-development
    transition: prompt

  - name: verify
    type: skill
    ref: superpowers:verification-before-completion
```

---

## Parallel Execution

```yaml
name: parallel-work
description: Run tasks simultaneously
steps:
  - name: setup
    type: bash
    run: echo "Starting..."

  - parallel:
      name: concurrent-tasks
      wait: all
      branches:
        - name: backend
          type: skill
          ref: superpowers:test-driven-development
          args: "backend API"
        - name: frontend
          type: skill
          ref: superpowers:test-driven-development
          args: "frontend UI"
        - name: tests
          type: bash
          run: npm run test:watch

  - name: integrate
    type: bash
    run: npm run build
```

---

## TDD Loop

```yaml
name: tdd-cycle
description: Test-driven development loop
steps:
  - loop:
      name: red-green-refactor
      until: "{{ all_tests_pass }}"
      max_iterations: 10
      steps:
        - name: write-test
          type: skill
          ref: superpowers:test-driven-development
          args: "write failing test"

        - name: run-tests
          type: bash
          run: npm test
          on_error: continue
          outputs:
            - all_tests_pass
            - failed_tests

        - name: fix
          type: skill
          ref: superpowers:systematic-debugging
          when: "{{ not all_tests_pass }}"
          args: "Fix: {{ failed_tests }}"

  - name: verify
    type: skill
    ref: superpowers:verification-before-completion
```

---

## Conditional Branching

```yaml
name: review-flow
description: Branch based on review result
steps:
  - name: implement
    type: skill
    ref: superpowers:test-driven-development

  - name: request-review
    type: skill
    ref: superpowers:requesting-code-review
    outputs:
      - review_approved

  - name: check-approval
    type: bash
    run: echo "Checking review status..."
    branch:
      if: "{{ review_approved }}"
      then: merge
      else: revise

  - name: revise
    type: skill
    ref: superpowers:receiving-code-review
    branch:
      if: "true"
      then: request-review
      else: request-review

  - name: merge
    type: command
    ref: /commit
```

---

## Full Feature Workflow

```yaml
name: fullstack-feature
description: Complete feature development
default_for:
  - task: feature
    keywords: ["add", "create", "implement", "build"]

defaults:
  on_error: ask
  transition: prompt

steps:
  - name: brainstorm
    type: skill
    ref: superpowers:brainstorming
    description: Explore requirements

  - name: plan
    type: skill
    ref: superpowers:writing-plans

  - parallel:
      name: implementation
      wait: all
      branches:
        - name: backend
          type: skill
          ref: superpowers:test-driven-development
          args: "backend"
        - name: frontend
          type: skill
          ref: superpowers:test-driven-development
          args: "frontend"

  - loop:
      name: quality
      until: "{{ tests_pass }}"
      max_iterations: 5
      steps:
        - name: test
          type: bash
          run: npm test
          outputs: [tests_pass]
        - name: fix
          type: skill
          ref: superpowers:systematic-debugging
          when: "{{ not tests_pass }}"

  - name: verify
    type: skill
    ref: superpowers:verification-before-completion

  - name: review
    type: skill
    ref: superpowers:requesting-code-review

  - name: finish
    type: skill
    ref: superpowers:finishing-a-development-branch
```

---

*These are reference examples. Build your own stack with `/stack build`.*
