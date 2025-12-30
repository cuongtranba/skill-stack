---
name: stack-run
description: Use when executing a skill workflow stack - handles sequential, parallel, loop, and branching execution
---

# Stack Run Skill

## Overview

Execute skill workflow stacks with support for sequential, parallel, loop, and branching patterns.

**Announce:** "I'm using the stack-run skill to execute this workflow."

## Pre-Execution

1. **Load stack YAML** from provided path
2. **Parse structure** including steps, defaults, extends
3. **Resolve includes** if stack references other stacks
4. **Show execution plan:**

```
Starting '[stack-name]' workflow...

Workflow Overview:
[Mermaid diagram from _meta.diagram]

Steps: [N] total
- Sequential: [N]
- Parallel blocks: [N]
- Loops: [N]

Ready to begin with '[first-step]'?
```

## Execution Engine

### Step Execution Order

```
For each item in steps:
  If item is regular step:
    Execute step
    Handle transition
  If item is parallel block:
    Execute parallel block
  If item is loop block:
    Execute loop block
```

### Regular Step Execution

```python
def execute_step(step):
    announce(f"Running step: {step.name}")

    if step.when and not evaluate(step.when):
        announce(f"Skipping {step.name} (condition not met)")
        return

    match step.type:
        case "skill":
            invoke_skill(step.ref, step.args)
        case "command":
            invoke_command(step.ref)
        case "bash":
            run_bash_with_timeout(step.run, step.timeout)
        case "stack":
            run_nested_stack(step.ref)

    capture_outputs(step.outputs)

    if step.branch:
        handle_branch(step.branch)
    else:
        handle_transition(step.transition)

def run_bash_with_timeout(command, timeout_seconds=120):
    """Execute bash command with timeout protection."""
    # Use timeout command (available on macOS and Linux)
    # Exit code 124 indicates timeout
    result = execute(f"timeout {timeout_seconds} bash -c '{command}'")

    if result.exit_code == 124:
        raise TimeoutError(f"Step timed out after {timeout_seconds}s")

    return result
```

### Parallel Block Execution

```python
def execute_parallel(block):
    announce(f"Starting parallel block: {block.name}")
    announce(f"Spawning {len(block.branches)} subagents...")

    # Use Task tool to spawn subagents
    tasks = []
    for branch in block.branches:
        task = spawn_subagent(
            name=branch.name,
            prompt=f"Execute: {branch}",
            run_in_background=True
        )
        tasks.append(task)

    # Wait based on mode
    match block.wait:
        case "all":
            wait_for_all(tasks)
        case "any":
            wait_for_any(tasks)
        case "none":
            pass  # Continue immediately

    announce(f"Parallel block '{block.name}' complete")
```

**Subagent prompt template:**
```
You are executing a parallel branch of the '[parent-stack-name]' workflow.

## Your Task

Step: [branch.name]
Type: [branch.type]
Reference: [branch.ref]
Args: [branch.args]

## Parent Workflow Context

Stack: [parent-stack-name]
Description: [parent-stack-description]
Current Phase: Parallel block '[block.name]'
Your Branch: [branch-index] of [total-branches]

## Available Context (from previous steps)

[For each captured output from earlier steps:]
- [output_name]: [output_value]

## Success Criteria

1. Complete the step fully according to its type
2. If type=skill: Invoke the skill and follow its guidance
3. If type=bash: Execute the command and capture exit code
4. If type=command: Run the command to completion

## Reporting

When complete, report:
- Status: success | failure | partial
- Duration: [time taken]
- Outputs: [any values captured]
- Notes: [relevant observations]

If you encounter errors:
- Report the error clearly
- Do NOT retry unless explicitly configured
- Let the parent workflow decide next steps
```

### Loop Block Execution

```python
def execute_loop(block):
    announce(f"Starting loop: {block.name}")
    iteration = 0
    max_iter = block.max_iterations or 10

    while iteration < max_iter:
        iteration += 1
        announce(f"Loop iteration {iteration}/{max_iter}")

        # Execute loop steps
        for step in block.steps:
            execute_step(step)

        # Check exit condition
        if block.until and evaluate(block.until):
            announce(f"Loop '{block.name}' complete (condition met)")
            break
        elif block.while_ and not evaluate(block.while_):
            announce(f"Loop '{block.name}' complete (while false)")
            break
        elif block.times and iteration >= block.times:
            announce(f"Loop '{block.name}' complete ({block.times} iterations)")
            break
    else:
        # Max iterations reached
        match block.on_max_reached:
            case "ask":
                ask_user("Max iterations reached. Continue or stop?")
            case "stop":
                raise LoopMaxReached()
            case "continue":
                pass
```

### Branch Handling

```python
def handle_branch(branch):
    condition_result = evaluate(branch.if_)

    if condition_result:
        target = branch.then
    else:
        target = branch.else_

    if target:
        jump_to_step(target)
```

### Transition Handling

```python
def handle_transition(transition):
    match transition:
        case "auto":
            pass  # Continue immediately
        case "prompt":
            ask_user("Ready for next step?")
        case "pause":
            ask_user("Paused. Type 'continue' to proceed.")
```

## Error Handling

```python
def handle_error(step, error):
    on_error = step.on_error or defaults.on_error

    match on_error:
        case "stop":
            announce(f"Error in {step.name}: {error}")
            raise WorkflowError()
        case "continue":
            announce(f"Warning in {step.name}: {error}")
            announce("Continuing to next step...")
        case "retry":
            for attempt in range(step.max_retries or 3):
                try:
                    execute_step(step)
                    return
                except:
                    continue
            raise WorkflowError("Max retries exceeded")
        case "ask":
            choice = ask_user(f"""
Error in {step.name}: {error}

Options:
1. Retry this step
2. Skip and continue
3. Stop workflow
4. Jump to specific step
""")
            handle_user_choice(choice)
```

## Output Capture

For steps with `outputs:` field:
```python
def capture_outputs(outputs):
    if not outputs:
        return

    for output_name in outputs:
        # Outputs are captured from:
        # 1. Bash exit codes and stdout
        # 2. Skill completion messages
        # 3. User responses

        value = extract_output(output_name)
        context[output_name] = value
```

## Condition Evaluation

For `when:`, `until:`, `if:` conditions:
```python
def evaluate(condition):
    # Simple template evaluation
    # {{ variable }} -> lookup in context
    # {{ not variable }} -> negate
    # Supports: and, or, not, ==, !=

    resolved = template_substitute(condition, context)
    return eval_boolean(resolved)
```

## Progress Tracking

Use TodoWrite to show progress:
```python
def track_progress(steps):
    todos = []
    for i, step in enumerate(steps):
        todos.append({
            "content": step.name,
            "status": "pending" if i > 0 else "in_progress",
            "activeForm": f"Running {step.name}"
        })
    TodoWrite(todos)
```

Update as each step completes.

## Completion

```
Workflow '[stack-name]' complete!

Summary:
- Steps executed: [N]
- Parallel blocks: [N]
- Loop iterations: [N]
- Time: [duration]

Outputs:
- [output_name]: [value]
- ...
```

## Guidelines

- Show clear progress indicators
- Use TodoWrite for step tracking
- Spawn subagents for parallel work
- Respect transition modes
- Capture and pass outputs between steps
- Handle errors per step configuration
