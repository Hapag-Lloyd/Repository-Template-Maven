#!/usr/bin/env bash
set -euo pipefail

#
# This script merges the current main branch into the init branches to keep them up-to-date. The commits are squashed.
#

git checkout main
git pull

# for all init branches
for branch in $(git branch --list "init-*"); do
  git checkout "$branch"
  git merge main

  # squash commits
  git reset --soft main
  git commit -m "chore: update init branch '$branch' with latest main branch changes"

  git push --force
done
