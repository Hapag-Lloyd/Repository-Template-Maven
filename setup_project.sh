#!/usr/bin/env bash
set -euo pipefail

#
# This script creates the PRs for all init branches.
#
# Note: As this script is developed in a template repository, it will be present in the newly created repositories as well.
#

force_execution="false"

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
  echo "Usage: $0 --force"

  echo "--force skip precondition checks"
  echo ""
  echo "Creates PRs for all init branches found in this repository."
  exit 1
}

function ensure_and_set_parameters_or_exit() {
  POSITIONAL_ARGS=()

  while [[ $# -gt 0 ]]; do
    case $1 in
      --force)
        force_execution="true"
        log_info "Force execution enabled"
        shift # past argument
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

  if [ "${#POSITIONAL_ARGS[@]}" -ne 0 ]; then
    show_help_and_exit
  fi
}

function ensure_dependencies_or_exit() {
  if ! command -v gh &> /dev/null; then
    log_error "gh is not installed. Please install it from https://cli.github.com/"
    exit 1
  fi
}

function ensure_repo_preconditions_or_exit() {
  if [ "$force_execution" == "true" ]; then
    log_warn "Force execution enabled. Skipping precondition checks."
    return
  fi

  # ensure a clean working directory
  if [ -n "$(git status --porcelain)" ]; then
    log_error "The working directory is not clean. Please use a clean copy so no unintended changes are merged."
    exit 1
  fi
}

function create_and_show_pr_for_init_branch() {
  local init_branch_name=$1

  git checkout "$init_branch_name"

  title=$(head -n1 pr-description.md)
  body=$(tail -n2 pr-description.md)

  rm pr-description.md
  git add .
  git commit -m "remove the PR description"
  git push

  gh pr create --title "$title" --body "$body" --base main --head "$init_branch_name"
  gh pr view --web
}

ensure_and_set_parameters_or_exit "$@"
ensure_dependencies_or_exit
ensure_repo_preconditions_or_exit

# find init- branches and create PRs for them
init_branches=$(git branch | grep "init-")

for init_branch in $init_branches; do
  create_and_show_pr_for_init_branch "$init_branch"
done
