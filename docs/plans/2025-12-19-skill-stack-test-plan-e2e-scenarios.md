# End-to-End Real-World Scenarios

> Simulates how different roles would use skill-stack in their daily work.

---

## Scenario E2E-1: Fullstack Developer - New Feature

### Context
A fullstack developer needs to implement a "user profile settings" feature. They want a workflow that ensures quality from design to deployment.

### Workflow Simulation

**Step 1: Build the Stack**
```
/stack build
```

**Conversation flow:**
```
Claude: "What's your primary role?"
User: Fullstack developer

Claude: "What kind of task is this stack for?"
User: New feature implementation

Claude: "What slows you down currently?"
User: I often forget to write tests first, and skip verification

Claude: "For a new feature, what do you do first?"
User: I brainstorm and design the approach

Claude: "What comes after design?"
User: I create a plan, then implement with TDD

Claude: "Do you need code review before finishing?"
User: Yes, and verification that everything works

Claude: "Should any steps run in parallel?"
User: Backend and frontend can be done in parallel

Claude: "Should this loop if tests fail?"
User: Yes, implement-test-fix should loop until passing
```

**Expected Stack Output:**
```yaml
name: fullstack-feature
description: End-to-end feature development with TDD
scope: personal

default_for:
  - task: new-feature
    keywords: ["add", "create", "implement", "build", "feature"]

steps:
  - name: brainstorm
    type: skill
    ref: superpowers:brainstorming
    transition: prompt
    description: Explore requirements and design

  - name: plan
    type: skill
    ref: superpowers:writing-plans
    transition: prompt
    description: Create implementation plan

  - parallel:
      name: implementation
      wait: all
      branches:
        - name: backend
          type: skill
          ref: superpowers:test-driven-development
          args: "backend API and database"
        - name: frontend
          type: skill
          ref: superpowers:test-driven-development
          args: "frontend UI components"

  - loop:
      name: quality-loop
      until: "{{ all_tests_pass }}"
      max_iterations: 5
      steps:
        - name: run-tests
          type: bash
          run: npm test
          on_error: continue
          outputs:
            - all_tests_pass
            - failed_tests
        - name: fix-issues
          type: skill
          ref: superpowers:systematic-debugging
          when: "{{ not all_tests_pass }}"
          args: "Fix: {{ failed_tests }}"

  - name: verify
    type: skill
    ref: superpowers:verification-before-completion
    transition: prompt

  - name: review
    type: skill
    ref: superpowers:requesting-code-review
    transition: prompt

  - name: finish
    type: skill
    ref: superpowers:finishing-a-development-branch
    transition: prompt
```

**Step 2: Use the Stack**

User starts working on "user profile settings" feature:
```
User: "I need to add user profile settings to the app"

Claude: "This looks like a new feature. I have a 'fullstack-feature'
        stack that matches. Want to use it?"

User: Yes
```

**Execution simulation:**
1. **Brainstorm** - Claude asks about requirements, explores edge cases
2. **Plan** - Creates implementation plan with tasks
3. **Parallel Implementation**
   - Backend subagent: Creates API endpoints, database models
   - Frontend subagent: Creates settings UI components
4. **Quality Loop**
   - Runs tests → 3 fail
   - Debugging skill fixes issues
   - Runs tests → all pass
5. **Verify** - Checks all requirements met
6. **Review** - Requests code review
7. **Finish** - Creates PR or merges

### Success Criteria
- [ ] Stack built through natural conversation
- [ ] Parallel execution spawns separate subagents
- [ ] Loop continues until tests pass
- [ ] All transitions respect configured mode
- [ ] Final PR/merge completes

---

## Scenario E2E-2: Frontend Developer - Component Library

### Context
A frontend developer builds UI components and needs a consistent workflow for creating accessible, tested, documented components.

### Workflow Simulation

**Step 1: Build the Stack**
```
/stack build
```

**Conversation flow:**
```
Claude: "What's your primary role?"
User: Frontend developer

Claude: "What kind of task is this stack for?"
User: Creating new UI components

Claude: "What's important in your component workflow?"
User: Accessibility, visual testing, documentation

Claude: "What do you do first when creating a component?"
User: Design it with Storybook, then implement

Claude: "How do you ensure quality?"
User: Visual tests, a11y checks, unit tests

Claude: "Any steps that can run in parallel?"
User: Yes - visual tests and a11y checks can run together
```

**Expected Stack Output:**
```yaml
name: frontend-component
description: Component development with a11y and visual testing
scope: personal

default_for:
  - task: component
    keywords: ["component", "ui", "button", "form", "modal"]

steps:
  - name: design
    type: skill
    ref: frontend-design:frontend-design
    transition: prompt
    description: Design component with Storybook

  - name: implement
    type: skill
    ref: superpowers:test-driven-development
    transition: prompt
    args: "React component implementation"

  - parallel:
      name: quality-checks
      wait: all
      branches:
        - name: visual-test
          type: bash
          run: npm run test:visual
        - name: a11y-check
          type: bash
          run: npm run test:a11y
        - name: unit-test
          type: bash
          run: npm run test:unit -- --coverage

  - name: document
    type: bash
    run: npm run storybook:build
    transition: auto

  - name: verify
    type: skill
    ref: superpowers:verification-before-completion
    transition: prompt
```

**Step 2: Use the Stack**

User: "Create a new DatePicker component"

**Execution simulation:**
1. **Design** - Creates Storybook stories, defines variants
2. **Implement** - TDD for DatePicker with tests first
3. **Quality Checks (parallel)**
   - Visual tests capture screenshots
   - A11y checks verify ARIA labels, keyboard nav
   - Unit tests verify logic
4. **Document** - Builds Storybook
5. **Verify** - Confirms all requirements

### Success Criteria
- [ ] Frontend-specific skills invoked
- [ ] Parallel quality checks all complete
- [ ] Storybook documentation generated
- [ ] Component meets a11y standards

---

## Scenario E2E-3: Backend Developer - API Development

### Context
A backend developer builds REST/GraphQL APIs with focus on security, performance, and proper documentation.

### Workflow Simulation

**Step 1: Build the Stack**
```
/stack build
```

**Conversation flow:**
```
Claude: "What's your primary role?"
User: Backend developer

Claude: "What kind of task is this stack for?"
User: Building new API endpoints

Claude: "What's critical in your API workflow?"
User: Security review, performance testing, API docs

Claude: "What do you do first?"
User: Design the API contract/schema

Claude: "How do you ensure API quality?"
User: Security scan, load testing, integration tests

Claude: "Should security and performance run together?"
User: Yes, after implementation
```

**Expected Stack Output:**
```yaml
name: backend-api
description: API development with security and performance focus
scope: personal

default_for:
  - task: api
    keywords: ["api", "endpoint", "rest", "graphql", "route"]

steps:
  - name: design-contract
    type: skill
    ref: superpowers:brainstorming
    transition: prompt
    args: "API contract design - endpoints, schemas, auth"

  - name: implement
    type: skill
    ref: superpowers:test-driven-development
    transition: prompt
    args: "API implementation with integration tests"

  - name: generate-docs
    type: bash
    run: npm run docs:api
    transition: auto

  - parallel:
      name: quality-gates
      wait: all
      branches:
        - name: security-scan
          type: bash
          run: npm run security:scan
          on_error: stop
        - name: load-test
          type: bash
          run: npm run test:load -- --quick
        - name: integration-test
          type: bash
          run: npm run test:integration

  - loop:
      name: security-fix-loop
      until: "{{ security_passed }}"
      max_iterations: 3
      steps:
        - name: check-security
          type: bash
          run: npm run security:audit
          outputs:
            - security_passed
            - security_issues
        - name: fix-security
          type: skill
          ref: superpowers:systematic-debugging
          when: "{{ not security_passed }}"
          args: "Fix security issues: {{ security_issues }}"

  - name: verify
    type: skill
    ref: superpowers:verification-before-completion
    transition: prompt

  - name: deploy-staging
    type: bash
    run: npm run deploy:staging
    transition: prompt
    on_error: ask
```

**Step 2: Use the Stack**

User: "Create a new /users/settings endpoint"

**Execution simulation:**
1. **Design Contract** - Define request/response schemas
2. **Implement** - TDD for endpoint with auth middleware
3. **Generate Docs** - OpenAPI/Swagger docs
4. **Quality Gates (parallel)**
   - Security scan checks for vulnerabilities
   - Load test verifies performance
   - Integration tests verify behavior
5. **Security Fix Loop** - Iterates until security audit passes
6. **Verify** - Confirms all requirements
7. **Deploy Staging** - Deploys to test environment

### Success Criteria
- [ ] API contract designed first
- [ ] Security scan runs and blocks if critical issues
- [ ] Load testing provides performance metrics
- [ ] Security loop fixes all vulnerabilities
- [ ] Staging deployment succeeds

---

## Scenario E2E-4: Project Manager - Feature Planning

### Context
A PM needs to take a feature request through discovery, planning, and handoff to development team.

### Workflow Simulation

**Step 1: Build the Stack**
```
/stack build
```

**Conversation flow:**
```
Claude: "What's your primary role?"
User: Project Manager

Claude: "What kind of task is this stack for?"
User: Planning new features for the team

Claude: "What's your planning process?"
User: Gather requirements, analyze impact, create specs, assign tasks

Claude: "Do you need stakeholder review?"
User: Yes, before finalizing specs

Claude: "How do you hand off to developers?"
User: Create tickets and notify team
```

**Expected Stack Output:**
```yaml
name: pm-feature-planning
description: Feature planning from discovery to dev handoff
scope: personal

default_for:
  - task: planning
    keywords: ["plan", "feature", "requirement", "spec", "ticket"]

steps:
  - name: gather-requirements
    type: skill
    ref: superpowers:brainstorming
    transition: prompt
    args: "Gather and clarify feature requirements"

  - name: impact-analysis
    type: skill
    ref: superpowers:brainstorming
    transition: prompt
    args: "Analyze technical impact, dependencies, risks"

  - name: create-spec
    type: bash
    run: |
      echo "Creating spec document..."
      mkdir -p docs/specs
    transition: prompt
    description: Create specification document

  - name: stakeholder-review
    type: skill
    ref: superpowers:requesting-code-review
    transition: prompt
    args: "Review feature spec with stakeholders"

  - loop:
      name: revision-loop
      until: "{{ spec_approved }}"
      max_iterations: 3
      steps:
        - name: check-approval
          type: bash
          run: echo "Checking stakeholder feedback..."
          outputs:
            - spec_approved
            - revision_notes
        - name: revise-spec
          type: skill
          ref: superpowers:brainstorming
          when: "{{ not spec_approved }}"
          args: "Address feedback: {{ revision_notes }}"

  - name: create-tickets
    type: bash
    run: |
      echo "Creating development tickets..."
      # gh issue create --title "Feature: ..." --body "..."
    transition: prompt

  - name: notify-team
    type: bash
    run: echo "Notifying development team..."
    transition: auto

  - name: handoff-complete
    type: bash
    run: echo "Feature planning complete. Ready for development."
```

**Step 2: Use the Stack**

User: "Plan the new dashboard analytics feature"

**Execution simulation:**
1. **Gather Requirements** - Claude asks clarifying questions about the feature
2. **Impact Analysis** - Identifies affected systems, dependencies
3. **Create Spec** - Generates specification document
4. **Stakeholder Review** - Sends for approval
5. **Revision Loop** - If not approved, revises based on feedback
6. **Create Tickets** - Generates dev tickets from spec
7. **Notify Team** - Alerts developers
8. **Handoff Complete** - Confirms ready for development

### Success Criteria
- [ ] Requirements captured comprehensively
- [ ] Impact analysis identifies risks
- [ ] Spec document created
- [ ] Revision loop handles feedback
- [ ] Tickets created for developers

---

## Scenario E2E-5: DevOps Engineer - Deployment Pipeline

### Context
A DevOps engineer needs a workflow for deploying services with proper checks, rollback capability, and monitoring.

### Workflow Simulation

**Step 1: Build the Stack**
```
/stack build
```

**Conversation flow:**
```
Claude: "What's your primary role?"
User: DevOps / SRE

Claude: "What kind of task is this stack for?"
User: Deploying services to production

Claude: "What checks do you need before deployment?"
User: Tests pass, security scan, staging verification

Claude: "What happens after deployment?"
User: Health checks, monitoring, rollback if needed

Claude: "Should pre-deploy checks run in parallel?"
User: Yes, to speed up the pipeline
```

**Expected Stack Output:**
```yaml
name: devops-deploy
description: Production deployment with safety checks
scope: personal

default_for:
  - task: deploy
    keywords: ["deploy", "release", "production", "rollout"]

steps:
  - name: pre-deploy-checks
    type: skill
    ref: superpowers:verification-before-completion
    transition: prompt
    args: "Verify ready for deployment"

  - parallel:
      name: safety-gates
      wait: all
      branches:
        - name: run-tests
          type: bash
          run: npm run test:all
          on_error: stop
        - name: security-scan
          type: bash
          run: npm run security:full
          on_error: stop
        - name: staging-verify
          type: bash
          run: npm run verify:staging

  - name: create-backup
    type: bash
    run: |
      echo "Creating rollback point..."
      # kubectl rollout history deployment/app
    transition: auto

  - name: deploy-production
    type: bash
    run: |
      echo "Deploying to production..."
      # kubectl apply -f k8s/production/
    transition: prompt
    on_error: ask

  - loop:
      name: health-check-loop
      until: "{{ service_healthy }}"
      max_iterations: 10
      steps:
        - name: wait
          type: bash
          run: sleep 30
        - name: check-health
          type: bash
          run: |
            echo "Checking service health..."
            # curl -f https://api.example.com/health
          outputs:
            - service_healthy

  - name: verify-metrics
    type: bash
    run: |
      echo "Verifying metrics..."
      # Check error rates, latency, etc.
    transition: prompt

  - name: rollback-decision
    type: bash
    run: echo "Deployment complete. Monitor for issues."
    branch:
      if: "{{ needs_rollback }}"
      then: rollback
      else: complete

  - name: rollback
    type: bash
    run: |
      echo "Rolling back..."
      # kubectl rollout undo deployment/app
    on_error: stop

  - name: complete
    type: bash
    run: echo "Deployment successful!"
```

**Step 2: Use the Stack**

User: "Deploy v2.3.0 to production"

**Execution simulation:**
1. **Pre-deploy Checks** - Verifies all prerequisites
2. **Safety Gates (parallel)**
   - All tests pass
   - Security scan clean
   - Staging verified
3. **Create Backup** - Saves rollback point
4. **Deploy Production** - Applies changes
5. **Health Check Loop** - Polls until healthy (max 5 min)
6. **Verify Metrics** - Checks error rates, latency
7. **Rollback Decision** - If issues, triggers rollback
8. **Complete** - Confirms success

### Success Criteria
- [ ] Pre-deploy checks comprehensive
- [ ] Safety gates block bad deployments
- [ ] Backup created before deploy
- [ ] Health check loop monitors correctly
- [ ] Rollback available if needed

---

## Scenario E2E-6: QA Engineer - Test Automation

### Context
A QA engineer needs a workflow for comprehensive testing including unit, integration, e2e, and performance tests.

### Workflow Simulation

**Step 1: Build the Stack**
```
/stack build
```

**Expected Stack Output:**
```yaml
name: qa-test-suite
description: Comprehensive test automation workflow
scope: personal

default_for:
  - task: testing
    keywords: ["test", "qa", "quality", "regression"]

steps:
  - name: analyze-changes
    type: bash
    run: git diff --name-only HEAD~1
    transition: auto
    outputs:
      - changed_files

  - name: determine-scope
    type: skill
    ref: superpowers:brainstorming
    transition: prompt
    args: "Determine test scope for: {{ changed_files }}"

  - parallel:
      name: test-suite
      wait: all
      branches:
        - name: unit-tests
          type: bash
          run: npm run test:unit -- --coverage
        - name: integration-tests
          type: bash
          run: npm run test:integration
        - name: e2e-tests
          type: bash
          run: npm run test:e2e

  - name: performance-test
    type: bash
    run: npm run test:performance
    transition: prompt
    on_error: continue

  - name: generate-report
    type: bash
    run: npm run test:report
    transition: auto

  - loop:
      name: fix-failures
      until: "{{ all_pass }}"
      max_iterations: 3
      steps:
        - name: analyze-failures
          type: skill
          ref: superpowers:systematic-debugging
          args: "Analyze test failures"
          outputs:
            - all_pass
            - failure_report
        - name: rerun-failed
          type: bash
          run: npm run test:failed
          when: "{{ not all_pass }}"

  - name: sign-off
    type: skill
    ref: superpowers:verification-before-completion
    transition: prompt
    args: "QA sign-off for release"
```

### Success Criteria
- [ ] Changed files analyzed for test scope
- [ ] All test types run in parallel
- [ ] Performance tests provide metrics
- [ ] Failure loop helps debug issues
- [ ] QA sign-off documented

---

## Test Execution Checklist

Run each scenario and document results:

| Scenario | Role | Status | Issues Found |
|----------|------|--------|--------------|
| E2E-1 | Fullstack Dev | | |
| E2E-2 | Frontend Dev | | |
| E2E-3 | Backend Dev | | |
| E2E-4 | Project Manager | | |
| E2E-5 | DevOps Engineer | | |
| E2E-6 | QA Engineer | | |

## Tester Info
- Name:
- Date:
- Plugin Version:
