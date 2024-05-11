# Repository-Template-Maven

Template repository for Maven projects. Don't forget to update the README.md file with the project information and initially
run

```shell
.github/update_workflows.sh
.github/update_templates.sh

# strongly suggested!
pre-commit install -c .github/pre-commit-config.yaml
```

## Development

### `init-` branches

The `init-` branches are used to initialize the project with the necessary files and configurations. Create them in this repository
and add a `pr-description.md` file with the description of the changes to be made. The first line contains the title of the PR
followed by a blank line and then the description.

Never merge these branches directly into the `main` branch.
