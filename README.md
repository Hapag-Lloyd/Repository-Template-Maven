# Repository-Template-Maven

Template repository for Maven projects. Don't forget to update the README.md file with the project information.

This repository is used to set up new projects using a Maven setup. It provides some `init` branches to set up all necessary files
and configurations.

## Initial PRs

Run `setup_project.sh` first to automatically create the initial PRs for setting up the project.

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

### Dictionaries

- use `.config/dictionaries/project.txt` to add project specific words to the spell checker exceptions.
- use `.config/dictionaries/maven.txt` to add all unknown words from files which are copied to other repositories.
