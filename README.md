# Repository-Template-Maven

Template repository for Maven projects. Don't forget to update the README.md file with the project information and initially
run

```shell
git checkout main
.github/update_templates.sh

# strongly suggested!
pre-commit install -c .github/pre-commit-config.yaml
```

In case a major release is published on the Workflow-Template repository, run `.github/update_workflows.sh`. This creates a PR
with the changes in the workflows. Carefully check the changes and merge them into the `main` branch.

## Development

### Usage

This repository is used as a template repository for new Maven projects. Thus the newly created repository will have the same
structure and configurations as this one.

After merging into the `main` branch, use `.github/update_init_branches.sh` to merge these changes into the `init-` branches as
well.

### `init-` branches

The `init-` branches are used to initialize the project with the necessary files and configurations. Create them in this repository
and add a `pr-description.md` file with the description of the changes to be made. The first line contains the title of the PR
followed by a blank line and then the description.

Never merge these branches directly into the `main` branch.
