#!/bin/bash

# HT (and shameless thieved from): https://andrewian.dev/blog/ai-git-commits/

# Check if ANTHROPIC_API_KEY is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "Error: ANTHROPIC_API_KEY environment variable is not set" >&2
  exit 1
fi

# Get git diff context
diff_context=$(git diff --cached --diff-algorithm=minimal)

if [ -z "$diff_context" ]; then
  echo "Error: No staged changes found" >&2
  exit 1
fi

# Get last 3 commit messages
recent_commits=$(git log -3 --pretty=format:"%B" | sed 's/"/\\"/g')

# Prepare the prompt
prompt="Generate a git commit message following this structure:
1. First line: conventional commit format (type: concise description) (remember to use semantic types like feat, fix, docs, style, refactor, perf, test, chore, etc.)
2. Optional bullet points if more context helps:
   - Keep the second line blank
   - Keep them short and direct
   - Focus on what changed
   - Always be terse
   - Don't overly explain
   - Drop any fluffy or formal language

Return ONLY the commit message - no introduction, no explanation, no quotes around it.

Examples:
feat: add user auth system

- Add JWT tokens for API auth
- Handle token refresh for long sessions

fix: resolve memory leak in worker pool

- Clean up idle connections
- Add timeout for stale workers

Simple change example:
fix: typo in README.md

Very important: Do not respond with any of the examples. Your message must be based off the diff that is about to be provided, with a little bit of styling informed by the recent commits you're about to see.

Recent commits from this repo (for style reference):
$recent_commits

Here's the diff:

$diff_context"

# Properly escape the prompt for JSON
json_escaped_prompt=$(jq -n --arg prompt "$prompt" '$prompt')

# Call Claude API with properly escaped JSON
response=$(curl -s https://api.anthropic.com/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  --data-raw "{
        \"model\": \"claude-3-sonnet-20240229\",
        \"max_tokens\": 300,
        \"messages\": [
            {
                \"role\": \"user\",
                \"content\": ${json_escaped_prompt}
            }
        ]
    }")

commit_message=$(echo "$response" | jq -r '.error.message')
if [[ commit_message == "null" ]]; then
  # Extract the commit message from the response
  commit_message=$(echo "$response" | jq -r '.content[0].text')
fi

# Output the commit message
echo "$commit_message"
