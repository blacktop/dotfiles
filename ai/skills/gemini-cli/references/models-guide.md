# Gemini Models Comparison Guide

Updated for Gemini 3 (January 2026)

---

## Available Models

### gemini-3-pro-preview

**Status**: 🆕 Latest flagship model

**Characteristics**:
- Google's most intelligent AI model
- State-of-the-art reasoning and multimodal understanding
- Supports text, image, video, audio, and PDF inputs
- Response time: ~15-30 seconds
- Higher cost

**Best For**:
- Complex reasoning tasks
- Critical architectural decisions
- Security audits
- Advanced multimodal understanding
- When absolute best quality is required

**Example**:
```bash
gemini -m gemini-3-pro-preview -p "Complex architectural decision requiring deep analysis"
cat architecture-diagram.png | gemini -m gemini-3-pro-preview -p "Analyze this system architecture"
```

---

### gemini-3-flash-preview (Default)

**Characteristics**:
- Fast response time: ~5-15 seconds
- Excellent quality for most tasks
- Prioritizes: Performance, simplicity, speed
- Lower cost

**Best For**:
- Code reviews
- Debugging (root cause analysis)
- Directory/file scanning
- General questions
- When speed matters

**Example**:
```bash
gemini -m gemini-3-flash-preview -p "Review this code"
echo "Error message here" | gemini -p "Help debug this error"
```

---

## When Models Disagree

**Critical Finding**: Flash and Pro can give **opposite recommendations** for the same question, and **both can be valid**.

**Example** (D1 vs KV for sessions):
- **Flash**: Recommends KV
  - Prioritizes: Performance, edge caching, TTL

- **Pro**: Recommends D1
  - Prioritizes: Strong consistency, SQL queries

**How to Handle**:
1. For critical/security decisions → Prefer Pro's perspective
2. For performance-sensitive apps → Consider Flash's perspective
3. For major architectural choices → Get both viewpoints:
   ```bash
   gemini -m gemini-3-flash-preview -p "Question?"
   gemini -m gemini-3-pro-preview -p "Same question"
   ```

---

## Model Selection Matrix

| Task Type | Recommended Model | Why |
|-----------|-------------------|-----|
| Quick questions | Flash | Fast, good quality |
| Architecture decisions | **Pro** | Thorough trade-off analysis |
| Security reviews | **Pro** | Catches subtle issues |
| Debug assistance | Flash | Root cause analysis sufficient |
| Code review | Flash | Comprehensive for most cases |
| Directory scanning | Flash | Pro may get confused |
| Whole project analysis | **Pro** | Better with 1M context |
| Complex multimodal tasks | **Pro** | Best multimodal understanding |

---

## Override Default Model

```bash
# Use Pro for single command
gemini -m gemini-3-pro-preview -p "Review this code" < src/auth.ts

# Set as environment variable for session
export GEMINI_MODEL=gemini-3-pro-preview
gemini -p "Review this code" < src/auth.ts
```

---

## Recommendations

**Default Strategy**: Use Flash for most tasks, Pro for critical decisions

**When to Use Pro**:
- Architecture decisions
- Security audits
- Major refactors
- Complex multimodal analysis
- When cost is not primary concern

**When Flash is Better**:
- Quick code reviews
- Debugging
- Directory/file scanning
- Non-critical questions
- Cost-sensitive workflows

---

**Last Updated**: 2026-01-25
