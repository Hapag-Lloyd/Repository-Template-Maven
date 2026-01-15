#!/usr/bin/env bash
set -euo pipefail

#
# This script updates the repository passed as path in $1 with the latest version of the templates. It creates a new branch
# and a pull request.
#

WORKFLOW_CONFIG_FILE=".config/workflow.yml"

skip_pr="false"
force_execution="false"
init_mode="false"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Output functions
log_info() {
  echo -e "${BLUE}ℹ ${NC}$*"
}

log_success() {
  echo -e "${GREEN}✓ ${NC}$*"
}

log_warn() {
  echo -e "${YELLOW}⚠ ${NC}$*"
}

log_error() {
  echo -e "${RED}✗ ${NC}$*"
}

log_section() {
  echo ""
  echo -e "${MAGENTA}════════════════════════════════════════${NC}"
  echo -e "${MAGENTA}${NC} $*"
  echo -e "${MAGENTA}════════════════════════════════════════${NC}"
}

function show_help_and_exit() {
  echo "Usage: $0 --force --skip-pr --init <repository-path>"

  echo "repository-path: the path to the repository to update"
  echo "--force: (optional) force execution even if the working directory is not clean"
  echo "--skip-pr: (optional) do not create a PR"
  echo "--init: (optional) creates PRs for one-time initialization branches (e.g., CODEOWNERS. LICENSE)"

  exit 1
}

function ensure_and_set_parameters_or_exit() {
  POSITIONAL_ARGS=()

  while [[ $# -gt 0 ]]; do
    case $1 in
      --init)
        init_mode="true"
        log_info "Initialization mode enabled"
        shift
        ;;
      --force)
        force_execution="true"
        log_info "Force execution enabled"
        shift
        ;;
      --skip-pr)
        skip_pr="true"
        log_info "Skip PR mode enabled"
        shift
        ;;
      --*|-*)
        log_error "Unknown option $1"
        show_help_and_exit
        ;;
      *)
        POSITIONAL_ARGS+=("$1") # save positional arg
        shift # past argument
        ;;
    esac
  done

  set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

  if [ "${#POSITIONAL_ARGS[@]}" -ne 1 ]; then
    show_help_and_exit
  fi

  repository_path=$1
  log_info "Repository path set to: $repository_path"
}

function ensure_dependencies_or_exit() {
  if ! command -v gh &> /dev/null; then
    echo "gh is not installed. Please install it from https://cli.github.com/"
    exit 1
  fi
}

function ensure_repo_preconditions_or_exit() {
  if [ ! -f "$repository_path/$WORKFLOW_CONFIG_FILE" ]; then
    echo "The repository does not contain the $WORKFLOW_CONFIG_FILE file. Please ensure that the repository is set up correctly."
    echo "See https://github.com/Hapag-Lloyd/Workflow-Templates"
    exit 1
  fi

  if [ "$force_execution" == "true" ]; then
    log_warn "Force execution enabled. Skipping precondition checks."
    return
  fi

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

function fetch_and_validate_configuration_from_file_or_exit() {
  log_section "Validating Configuration"
  repository_type=$(yq e '.repository.type' "$CONFIG_FILE")

  log_info "Repository type: $repository_type"

  if [ "$repository_type" != "maven" ]; then
    log_error "These templates are for Maven repos only!"
    exit 3
  fi
}

function create_and_show_pr_for_init_branch() {
  local init_branch_name=$1
  local local_branch_name=$2

  git checkout -b "$local_branch_name" origin/main
  git merge --no-ff --allow-unrelated-histories "$init_branch_name" -m "chore(deps): apply initialization from $init_branch_name"

  title=$(head -n1 pr-description.md)
  body=$(tail -n2 pr-description.md)

  rm pr-description.md
  git add .
  git commit -m "remove the PR description"
  git push

  if [ "$skip_pr" == "false" ]; then
    gh pr create --title "$title" --body "$body" --base main --head "$branch_name"
    gh pr view --web
  fi
}

ensure_and_set_parameters_or_exit "$@"
ensure_dependencies_or_exit
ensure_repo_preconditions_or_exit

# to get rid of "." and windows paths
latest_template_path=$(cd "$(dirname "$0")" && pwd)
branch_name="update-templates-$(date +%s)"

cd "$repository_path"

# create a new branch to update the templates
git checkout -b "$branch_name"

# update issue templates
cp -r "$latest_template_path/.github/ISSUE_TEMPLATE" .github/

# update pull request template
cp "$latest_template_path/.github/PULL_REQUEST_TEMPLATE.md" .github/

# update contributing guidelines
cp "$latest_template_path/.github/CONTRIBUTING.md" .github/

# update the update scripts
cp "$latest_template_path/update_templates_user.sh" .github/update_templates.sh

# create a commit, push it and open a pull request
git add .github
git commit -m "chore(deps): update project templates"
git push --set-upstream origin "$branch_name"

if [ "$skip_pr" == "false" ]; then
  gh pr create --title "chore(deps): update project templates" --body "This PR updates the project templates." --base main --head "$branch_name"

  echo "The project templates have been updated. Please review and merge the pull request."
  gh pr view --web
fi

if [ "$init_mode" == "true" ]; then
  # find init- branches and create PRs for them
  init_branches=$(cd "$latest_template_path" && git branch | grep "init-")

  git remote add init-templates "$latest_template_path"
  git fetch init-templates

  for init_branch in $init_branches; do
    create_and_show_pr_for_init_branch "init-templates/$init_branch" "$init_branch-$(date +%s)"
  done

  git remote remove init-templates
fi
