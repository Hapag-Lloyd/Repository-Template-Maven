#!/usr/bin/env bash

#
# This script updates the current repository with the latest version of the workflows. It creates a new branch and a pull request.
#

function ensure_dependencies_or_exit() {
  if ! command -v gh &> /dev/null; then
    echo "gh is not installed. Please install it from https://cli.github.com/"
    exit 1
  fi
}

function ensure_repo_preconditions_or_exit() {
  # ensure main branch
  if [ "$(git branch --show-current)" != "main" ]; then
    echo "The current branch is not main. Please switch to the main branch."
    exit 1
  fi

  # ensure a clean working directory
  if [ -n "$(git status --porcelain)" ]; then
    echo "The working directory is not clean. Please use a clean copy so no unintended changes are merged."
    exit 1
  fi
}

latest_workflows_path=$(mktemp -d -t repository-template)

gh repo clone https://github.com/Hapag-Lloyd/Workflow-Template.git "$latest_workflows_path"

# update the workflows
(
  cd "$latest_workflows_path" || exit 7
  ./update_workflows.sh .. maven
)
