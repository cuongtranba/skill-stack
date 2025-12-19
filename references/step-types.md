# Step Types Reference

## skill

Invoke a Claude Code skill.

```yaml
- name: brainstorm
  type: skill
  ref: superpowers:brainstorming
  args: "Explore feature requirements"
  transition: prompt
```

**ref formats:**
- `plugin:skill-name` - Plugin skill (e.g., `superpowers:brainstorming`)
- `skill-name` - Personal skill (e.g., `my-custom-skill`)

---

## command

Invoke a Claude Code command.

```yaml
- name: commit-changes
  type: command
  ref: /commit
  transition: prompt
```

**ref formats:**
- `/command-name` - Built-in or custom command
- `command-name` - Without slash

---

## bash

Run a shell command.

```yaml
- name: run-tests
  type: bash
  run: npm test
  on_error: continue
  outputs:
    - tests_pass
```

**Multiline:**
```yaml
- name: setup
  type: bash
  run: |
    npm install
    npm run build
    npm test
```

---

## stack

Run a nested stack.

```yaml
- name: verification-flow
  type: stack
  ref: verify-stack
  transition: prompt
```

Nested stacks inherit context from parent.

---

## Comparison

| Type | Use When | Execution |
|------|----------|-----------|
| skill | Need Claude assistance | Invokes skill, waits for completion |
| command | Simple command invocation | Runs command directly |
| bash | Shell operations | Runs in shell, captures output |
| stack | Reusable sub-workflows | Loads and executes nested stack |
