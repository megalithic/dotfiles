#!/bin/bash
#
# HT (and shameless thieved from): https://andrewian.dev/blog/ai-git-commits/

# Get AI-generated commit message
commit_message=$($DOTS/bin/ai_commit_msg.sh)

# Use git commit -m with -e to edit
git commit -m "$commit_message" -e
