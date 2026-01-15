#!/usr/bin/env bash

#
# Copied into .github/workflows/ via update_templates.sh and executed in the repository to be updated.
#

set -euo pipefail

# clone the workflows repository into a temporary directory
TEMPLATE_REPO_CLONED_PATH=$(mktemp -d)

# cleanup temp directory on exit
trap 'rm -rf "$TEMPLATE_REPO_CLONED_PATH"' EXIT

git clone https://github.com/Hapag-Lloyd/Repository-Template-Maven.git "$TEMPLATE_REPO_CLONED_PATH"

TOP_LEVEL_DIR=$(cd "$(git rev-parse --show-toplevel)" && pwd)

# do the job and pass all arguments
"$TEMPLATE_REPO_CLONED_PATH/update_templates.sh" "$TOP_LEVEL_DIR" "$@"
