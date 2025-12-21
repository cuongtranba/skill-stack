# WCAG 2.1 A/AA Criteria Reference

## Contrast Requirements

| Element Type | Minimum Ratio |
|--------------|---------------|
| Normal text (< 18pt) | 4.5:1 |
| Large text (≥ 18pt or 14pt bold) | 3:1 |
| UI components, icons, focus indicators | 3:1 |

### Common Tailwind Failures

| Class | Ratio on White | Status |
|-------|----------------|--------|
| `gray-400` | 2.68:1 | FAIL |
| `gray-500` | 4.54:1 | PASS |
| `placeholder-gray-400` | 2.68:1 | FAIL |
| `text-white` on `bg-blue-400` | ~2.5:1 | FAIL |

## Critical Issues (Level A)

| WCAG | Criterion | Check |
|------|-----------|-------|
| 1.1.1 | Non-text Content | Images missing `alt` |
| 1.3.1 | Info and Relationships | Inputs without labels, tables without headers |
| 2.1.1 | Keyboard | `onClick` without keyboard handler |
| 4.1.2 | Name, Role, Value | Icon buttons without `aria-label` |

## Major Issues (Level A/AA)

| WCAG | Criterion | Check |
|------|-----------|-------|
| 1.4.3 | Contrast (Minimum) | Text contrast < 4.5:1 |
| 2.4.4 | Link Purpose | Generic link text ("click here") |
| 1.3.5 | Identify Input Purpose | Inputs missing `autocomplete` |
| 2.5.3 | Label in Name | `aria-label` doesn't match visible text |

## Minor Issues (Level AA)

| WCAG | Criterion | Check |
|------|-----------|-------|
| 1.4.4 | Resize Text | Font sizes in `px` not `rem` |
| 2.4.6 | Headings and Labels | Empty/skipped headings |
| 1.4.10 | Reflow | Fixed widths > 320px |

## Manual Verification Required

- 1.2.1 Media alternatives
- 1.3.3 Sensory-only instructions
- 1.4.1 Color-only meaning
- 2.1.2 Keyboard trap
- 2.4.3 Focus order
- 2.4.7 Focus visible
- 3.1.1 Lang attribute
- 4.1.1 Valid HTML
