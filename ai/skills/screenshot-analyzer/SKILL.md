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

Open the chosen screenshot with your image-viewing tool.

### 3. Review

Evaluate what the image actually shows: visual hierarchy, layout and spacing, typography, color contrast (WCAG), interactive affordances and focus states, error states and feedback, and consistency with the app's design system. Skip areas the screenshot does not show.

## Output Format

Start with `## Screenshot Analysis: <filename>` and one or two sentences on what the screenshot shows. Then list issues, most severe first, each as `**[Issue type]**: what is wrong and where → suggested fix`. Mention strengths only when they bear on a fix.
