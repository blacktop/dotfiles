#!/bin/bash
# Test Gemini CLI installation and connectivity
# Part of gemini-cli skill (v2.0.0+)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Gemini CLI Integration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Check if Gemini CLI is installed
echo "1️⃣  Checking Gemini CLI installation..."
if ! command -v gemini &> /dev/null; then
  echo "   ❌ Gemini CLI not found"
  echo ""
  echo "   Install with:"
  echo "     npm install -g @google/gemini-cli"
  echo ""
  exit 1
else
  echo "   ✅ Gemini CLI found"
  gemini --version 2>&1 | sed 's/^/   /'
fi

echo ""

# Test 2: Check API connectivity with simple question
echo "2️⃣  Testing Gemini API connectivity..."
echo "   Running: echo \"What is 2+2?\" | gemini -p \"Answer briefly\""
echo ""

if output=$(echo "What is 2+2?" | gemini -p "Answer briefly" 2>&1); then
  echo "   ✅ Gemini CLI executed successfully"
  echo ""
  echo "   Response preview:"
  echo "$output" | head -5 | sed 's/^/   /'
  echo ""
else
  echo "   ❌ Gemini CLI failed"
  echo ""
  echo "   Error:"
  echo "$output" | sed 's/^/   /'
  echo ""
  echo "   Common issues:"
  echo "   • Not authenticated: Run 'gemini' and follow auth prompts"
  echo "   • Rate limit exceeded: Wait 1-5 minutes"
  echo "   • Network issue: Check internet connection"
  echo ""
  exit 1
fi

# Test 3: Check if /ask-gemini slash command is installed (optional)
echo "3️⃣  Checking /ask-gemini slash command..."
if [ -f "$HOME/.claude/commands/ask-gemini.md" ]; then
  echo "   ✅ /ask-gemini command found"
else
  echo "   ⚠️  /ask-gemini command not found (optional)"
  echo ""
  echo "   Install with:"
  echo "     ./scripts/setup-slash-command.sh"
  echo ""
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All tests passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "You can now use:"
echo "  gemini -p \"Your question\""
echo "  cat file.ts | gemini -p \"Review this code\""
echo "  gemini -m gemini-3-pro-preview -p \"Architecture question\""
echo "  cat ./src | gemini -m gemini-3-pro-preview -p \"Security audit\""
echo ""
echo "Or from Claude Code sessions:"
echo "  /ask-gemini Your question here"
echo ""
