# Karpathy Guidelines — Examples

## Surface Assumptions

### Bad: Silent assumptions

User asks "add a feature to export user data" — LLM assumes all users, JSON format, file path, field selection.

### Good: Present interpretations

```
Before implementing, I need to clarify:
1. Scope: All users or filtered? (privacy implications)
2. Format: Download, background job, or API endpoint?
3. Fields: Which fields? Some may be sensitive.
4. Volume: How many users? (affects approach)
```

## Minimum Viable Change

### Bad: Strategy pattern for one discount type

```python
class DiscountStrategy(ABC):
    @abstractmethod
    def calculate(self, amount: float) -> float: ...

class PercentageDiscount(DiscountStrategy): ...
class FixedDiscount(DiscountStrategy): ...
class DiscountCalculator: ...
# 60+ lines for a single calculation
```

### Good: One function

```python
def calculate_discount(amount: float, percent: float) -> float:
    return amount * (percent / 100)
```

Add complexity when you actually need multiple discount types.

## Surgical Edits

### Bad: Drive-by refactoring during a bug fix

User asks to fix empty email crash. LLM also: changes quote style, adds type hints, adds docstrings, reformats whitespace, adds username validation.

### Good: Only fix the bug

```diff
- if not user_data.get('email'):
+ email = user_data.get('email', '')
+ if not email or not email.strip():
      raise ValueError("Email required")
```

### Bad: Style drift while adding logging

LLM changes `''` to `""`, adds type hints, restructures boolean returns.

### Good: Match existing style, add only logging

```diff
+ logger.info(f'Starting upload: {file_path}')
  # ... existing code untouched ...
+             logger.info(f'Upload successful: {file_path}')
```

## Verifiable Goals

### Bad: Vague plan

"I'll review the code, identify issues, and make improvements."

### Good: Incremental with checks

```
Plan for rate limiting:
1. In-memory rate limit on one endpoint
   → verify: 11th request gets 429
2. Extract to middleware
   → verify: limits apply to /users and /posts
3. Redis backend for multi-server
   → verify: limit persists across restarts
```

Each step is independently verifiable and deployable.
