#!/usr/bin/env bash
set -euo pipefail

#
# This script updates the current repository with the latest version of the workflow files. It creates a new branch and a
# pull request.
#

function ensure_dependencies_or_exit() {
  if ! command -v yq &> /dev/null; then
    echo "yq is not installed. https://github.com/mikefarah/yq"
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

function fix_workflow_files() {
  local git_workflow_ref=$1

  # Fix the "on" clause in the workflow files, remove all jobs and set a reference to this repository

  # iterate over each file in the directory
  for file in .github/workflows/*.yml
  do
    base_name=$(basename "$file")

    # remove everything else as we will reference the file in this repository
    sed -i '/jobs:/,$d' "$file"

    cat >> "$file" <<-EOF
  jobs:
    default:
      uses: Hapag-Lloyd/Workflow-Templates/.github/workflows/$base_name@$workflow_ref
      secrets: inherit
  EOF

    # add TODOs for the parameters of the workflow
    # false positive, variable is quoted
    # shellcheck disable=SC2086
    if [ "$(yq '.on["workflow_call"] | select(.inputs) != null' $file)" == "true" ]; then
      cp "$file" "$file.bak"
      echo "    with:" >> "$file"

      yq '.on.workflow_call.inputs | keys | .[]' "$file".bak | while read -r input; do
        type=$(yq ".on.workflow_call.inputs.$input.type" "$file".bak)
        required=$(yq ".on.workflow_call.inputs.$input.required" "$file".bak)
        description=$(yq ".on.workflow_call.inputs.$input.description" "$file".bak)

        cat >> "$file" <<-EOF
        # TODO insert correct value for $input
        # type: $type
        # required: $required
        # description: $description
        $input: "my-special-value"
  EOF
      done

      rm "$file.bak"
    fi

    # remove the comment char for all lines between USE_REPOSITORY and /USE_REPOSITORY in the file
    sed -i '/USE_REPOSITORY/,/\/USE_REPOSITORY/s/^#//' "$file"

    # remove the everything between USE_WORKFLOW and /USE_WORKFLOW
    sed -i '/USE_WORKFLOW/,/\/USE_WORKFLOW/d' "$file"

    # remove the marker lines
    sed -i '/USE_REPOSITORY/d' "$file"
    sed -i '/\/USE_REPOSITORY/d' "$file"
    sed -i '/USE_WORKFLOW/d' "$file"
    sed -i '/\/USE_WORKFLOW/d' "$file"
  done

  #
  # Remove the prefix from the workflow files
  #
  prefixes=("default_" "terraform_module_" "docker_" "maven_")

  # iterate over each file in the directory
  for file in .github/workflows/*.yml
  do
    # get the base name of the file
    base_name=$(basename "$file")

    # iterate over each prefix
    for prefix in "${prefixes[@]}"
    do
      # check if the file name starts with the prefix
      if [[ $base_name == $prefix* ]]; then
        # remove the prefix
        new_name=${base_name#"$prefix"}

        # rename the file
        mv "$file" .github/workflows/$new_name

        # break the loop as the prefix has been found and removed
        break
      fi
    done
  done

  #
  # Remove the suffix from the workflow files
  #
  suffixes=("_callable.yml")

  # iterate over each file in the directory
  for file in .github/workflows/*.yml
  do
    # get the base name of the file
    base_name=$(basename "$file")

    # iterate over each suffix
    for suffix in "${suffixes[@]}"
    do
      # check if the file name starts with the prefix
      if [[ $base_name == *$suffix ]]; then
        # remove the suffix
        new_name="${base_name%"$suffix"}.yml"

        # rename the file
        mv "$file" .github/workflows/$new_name

        # break the loop as the suffix has been found and removed
        break
      fi
    done
  done
}

ensure_dependencies_or_exit
ensure_repo_preconditions_or_exit

latest_template_path=$(mktemp -d -t repository-template)
new_branch_name=$(basename "$latest_template_path")

# clone the default branch to get the latest version of the template files
gh repo clone https://github.com/Hapag-Lloyd/Workflow-Template.git "$latest_template_path"
workflow_commit_sha=$(cd $latest_template_path && git rev-parse HEAD)

# create a new branch to update the templates
git checkout -b "$new_branch_name"

# basic workflows
mkdir -p .github/workflows
cp "$latest_template_path"/.github/workflows/default_* "$destination_path/.github/workflows/"

# release workflow
rm -f .github/workflows/default_release_*
cp "$latest_template_path"/.github/workflows/maven_release_* .github/workflows/

# adjust the workflow files (naming, variables, etc.)
fix_workflow_files $workflow_commit_sha

# create a commit, push it and open a pull request
git add .github
git commit -m "chore: update project templates"
git push --set-upstream origin "$new_branch_name"

gh pr create --title "chore: update project templates" --body "This PR updates the project templates." --base main --head "$new_branch_name"

echo "The project templates have been updated. Please review and merge the pull request."
gh pr view --web
