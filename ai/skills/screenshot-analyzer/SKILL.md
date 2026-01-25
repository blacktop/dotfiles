---
name: screenshot-analyzer
description: Find and analyze screenshots from ~/Downloads/Screenshots/ for UI/UX review. Use when asked to look at screenshots, review UI designs, inspect interface errors, analyze layout issues, or examine visual problems. Triggers on "check my latest screenshot", "review my UI", "analyze this screen capture".
---

# Screenshot Analyzer

Find and analyze screenshots from `~/Downloads/Screenshots/` with focus on UI/UX review.

## Workflow

### 1. Find Screenshots

List recent screenshots sorted by modification time:

```bash
ls -t ~/Downloads/Screenshots/*.png | head -5
```

Adjust `-5` to show more/fewer files as needed.

### 2. Read and Analyze

Use the Read tool to view the screenshot image:

```
Read: ~/Downloads/Screenshots/<filename>.png
```

The Read tool renders images visually for analysis.

### 3. UI/UX Review Checklist

When analyzing, evaluate:

**Visual Hierarchy**
- Clear focal points and content prioritization
- Logical flow of information
- Appropriate use of size, color, and spacing to guide attention

**Layout & Spacing**
- Consistent margins and padding
- Proper alignment of elements
- Balanced whitespace usage

**Typography**
- Readable font sizes and line heights
- Appropriate font choices and hierarchy
- Sufficient contrast for legibility

**Color & Contrast**
- WCAG-compliant contrast ratios
- Consistent color palette
- Meaningful use of color (not just decorative)

**Interactive Elements**
- Clear affordances for buttons/links
- Visible focus states
- Appropriate touch/click target sizes

**Error States & Feedback**
- Clear error messaging
- Helpful guidance for resolution
- Appropriate visual indicators

**Consistency**
- Consistent patterns across similar elements
- Adherence to design system (if applicable)
- Predictable interaction patterns

## Output Format

Structure findings as:

```
## Screenshot Analysis: <filename>

### Summary
[1-2 sentence overview of what the screenshot shows]

### Findings

#### Strengths
- [Positive observation 1]
- [Positive observation 2]

#### Issues
- **[Issue Type]**: [Description] → [Suggested fix]
- **[Issue Type]**: [Description] → [Suggested fix]

### Priority Recommendations
1. [Most critical fix]
2. [Second priority]
3. [Third priority]
```
