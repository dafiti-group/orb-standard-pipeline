# Orb Source

[![CircleCI Build Status](https://circleci.com/gh/dafiti-group/orb-standard-pipeline.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/dafiti-group/orb-standard-pipeline) [![CircleCI Orb Version](https://badges.circleci.com/orbs/dafiti-group/orb-standard-pipeline.svg)](https://circleci.com/orbs/registry/orb/dafiti-group/orb-standard-pipeline) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/dafiti-group/orb-standard-pipeline/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

## Before all

**_Install circleci cli interface_**

<https://circleci.com/docs/2.0/local-cli>

And [setup `circlecli` CLI with your token](https://circleci.com/docs/2.0/local-cli#configuring-the-cli)

____

Highly recommended to read:

- [Original README.md WEB file](https://github.com/CircleCI-Public/Orb-Template/blob/main/README.md)
- [GitHub guidelines to create a new version](./docs/LEGACY_EXTERNAL_README.md)
- [Guidelines to pack orb](./docs/LEGACY_INTERNAL_README.md)

## Development

Use the command:

```sh
make dev
```

This command will generate a temp deployment with the named `dafiti-group/orb-standard-pipeline@dev:first` and you need to place this orb version in any other project to test like the `YAML` below:

```yaml
#.circleci/config.yml
version: 2.1
orbs:
  dft: dafiti-group/orb-standard-pipeline@dev:first
  # ...
  workflows:
    deployment-flow:
      jobs:
        # ...
        # dft/job-to-test-with:
```

## Others options

```sh
make validate # to check orb integration
make pack # to generate orb.yml to deploy
```
