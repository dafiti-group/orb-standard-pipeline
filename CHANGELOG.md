# orb-standard-pipeline

## `[4.0.0 2025-03-18]`

**__BREAKIN_CHANGES__**

Pipelinei context for lambdas using `sam-test` and `sam-deploy` has major changes ang behavior
changes.

Now the `sam-deploy` has parameter `use_container` to switch between `true/false` value and change `sam build` command behavior. 

the job `sam-test` was deprecated and your application should use `unit-test` job using the default Docker behavior for unity testing and sonarqube coverage

To adjust your pipeline, you need to create a `Dockerfile` and `docker-compose.yaml` file with service name `ci` to use job name `unit-test`

Example pipeline shows the new pipeline layout to adopt.

### Changes

- `sam-deploy` job has changes to fit new deployment standard

### Added

N\A

### Removed

- `sam-test` This job was removed to stand only `unit-test` job using docker, removing stack knowledge from pipeline to Docker context

___


## `[3.9.0 2025-03-06]`

### Changes

N/A

### Added

- New job to auto approve PRs.

### Removed

N/A

___


## `[3.8.0 2025-02-11]`

### Changes

N/A

### Added

- Add a job bearer for a SAST scan that comments on the PR with a description and resolution of the vulnerability.

### Removed

- Remove example to `deploy-latam.yaml` with jobs that delivery in GITLAB.

___


## `[3.7.0 2024-10-29]`

### Changes

- `eks-deploy` job change argument `country` now using the environment `COUNTRY`.
- `eks-promote` job change argument `country` now using the environment `COUNTRY`.

### Added

- `examples` of pipeline using `gitops` to deploy multi-country

### Removed

N\A

___


## `[3.6.0 2024-08-23]`

### Changes

- `unit-test` job include a extra argument `services` to include more items to be build on unit-testing context. The arg type is a `string` and should separate with `spaces`. Ex:

    ```yaml
    version: 2.1
    workflows:
      deployment-flow:
        jobs:
          - dft/unit-test:
              name: unit-test
              services: "flyway_test mysql_test"
    ```

### Added

N\A

### Removed

N\A

___


## `[3.5.0 2024-06-10]`

### Changes

- Changed `unit-test` job to set custom executor (runner)
- Changed `sam-deploy` job to set custom executor (runner)
- Changed `deploy-to-s3` job to set custom executor (runner)
- Changed `deploy-to-s3` job to include two new parameters so that it is possible to set up and deploy S3 artifacts without Docker build

### Added

- Include new `executor` type `machine` to execute jobs in machines
- Include `arguments` parameter in `deploy-to-s3` job

### Removed

N\A

___

## `[3.4.0 2024-02-19]`

### Changes

- Changed default repo from argo to gitops in `commands/clone_gitops.yaml`.
- Included gitlab's git configuration in scripts `config_git`.
- Include `git pull --rebase` in promote jobs to prevent conflicts on `push`

### Added

- Added job `eks-deploy-gitlab`. It just change the image tag in `ncharts` repository on gitlab.
- Added job `eks-promote-gitlab`. It promotes the tag in preprod to prod file.
- Added commands `clone_ncharts` to download the gilab ncharts repo.
- Added Country in `grafana-notify` script.

### Removed

N\A

___


## `[3.3.0 2024-01-18]`

### Changes

- Changed the command `config_docker` version `src/commands/config_docker.yml`
- Changed the version `docker_version` to setup build in job `ecr-build-and-push`

### Added

- Added variables `path` and `no_output_timeout` in job `ecr-build-and-push`

### Removed

N\A

___


## `[3.2.0 2023-11-08]`

### Changes

- New executor `arn` to be used in `ecr-build-and-push`
- Update `job ecr-build-and-push` including a new parameter `docker_version` to setup custom docker versions
- Update command `config_docker`  including a new parameter `version` to setup docker context

### Added

N\A

### Removed

N\A

___


## `[3.1.2 2023-07-24]`

### Changes

- dft/eks-deploy fix the action for rollback, stop validating if the hash existis in github and validate if the aws ecr has the desired image hash

### Added

N\A

### Removed

N\A

___

## `[3.1.1 2023-07-12]`

### Changes

Fix jobs:

- `eks-deploy`
- `eks-promote`

Booth of then now has a flag `use_yq` with default value `true` that change the behavior of the action to change image tag in deployment file.

The default image `cimg/base:stable` has the binary `yq` <https://mikefarah.gitbook.io/yq/> already installed that make ease to change values in yaml file like a pro.

This feature will only work when de deployment file is a `kustomization.yaml` file that has the yaml structure like:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: example
helmCharts:
  - name: my-helm
    version: 0.0.1
    repo: https://my-repo.io
    valuesInline:
      image:
        tag: "767ccdc" 
```

Then the command:

```sh
yq -i '.helmCharts[0].valuesInline.image.tag = "[new value]"'
```


### Added

N\A

### Removed

N\A

___


## `[3.1.0 2023-07-04]`

### Changes

Included `sonarqube` **COVERAGES**

[More info at Confluence page](https://dafiti.jira.com/wiki/spaces/PLAT/pages/3778314987/Cobertura+de+testes)

- The docker image of `sonarqube` executor changed from: `newtmitch/sonar-scanner:4` to: `sonarsource/sonar-scanner-cli:4`
- job `unit-test` include new parameters:
  - **`has_coverage`**: `boolean` to flag project that has coverage, default `false`
  - **`coverage_file`** The name of the coverage file generated in test, default ""
  - **`container_work_dir`** The base path inside container, default "/app/"
- job `sonarqube` include new parameters:
  - **`has_coverage`**: `boolean` to flag project that has coverage, default `false`

### Migrating to this version and using sonar coverage

- Requirements:
  - Your project must generate a valid file source to be uploaded to `Sonarqube` in the san
    - Some examples:

      ```sh
      # golang ======
      go test -coverprofile=profile.cov ./... 
      # will generate a file [profile.cov]
      
      # php ======
      XDEBUG_MODE=coverage phpunit --coverage-clover clover.xml --testdox --color 
      # will generate a file [clover.xml]
      
      # nodejs =====
      # you must config your jest correctly before executing the command below!
      jest --collect-coverage
      # the command above will produce a file [lcov.info]
      ```

      >Remember to add the coverage file to .gitignore file!
  - Your project `MUST HAVE` a file in the root called `sonar-project.properties` as the example below:

    ```ini
    # find the right [STACK_KEY_PROPERTY] at https://docs.sonarqube.org/10.0/analyzing-source-code/test-coverage/test-coverage-parameters/
    # some examples of [STACK_KEY_PROPERTY]:
    #   sonar.go.coverage.reportPaths
    #   sonar.coverage.jacoco.xmlReportPaths
    #   sonar.jacoco.reportPaths
    #   sonar.javascript.lcov.reportPaths
    #   sonar.php.coverage.reportPaths
    #   sonar.python.coverage.reportPaths
    [STACK_KEY_PROPERTY]= # place here the generate file
    sonar.coverage.exclusions= # place here the exclusions
    sonar.test.inclusions= # place here tye inclusions
    sonar.qualitygate.wait=true
    ```

- Pipeline adjustment:

    ```yaml
    #...
    orbs:
      dft: dafiti-group/orb-standard-pipeline@3.1.0 # or greater
    #...
    workflows:
      #...
      deployment-flow:
        #...
        - dft/unit-test:
            name: unit-test
            #...
            has_coverage: true
            coverage_file: profile.cov # from go example
            container_work_dir: /app/ # where inside container the generated file is placed to be copied to workplace
        - dft/sonarqube:
            name: sonarqube
            #...
            has_coverage: true
            requires: ['unit-test']
      #...
    ```

___

## `[3.0.3 2023-06-30]`

### Changes

- fix block PR function, now just block PR that destiny is HEAD Branch

### Added

N\A

### Removed

N\A
## `[3.0.2 2023-04-25]`

### Changes

- updated `dft/sam-deploy` to use `machine` instead of `docker` engine

### Added

N\A

### Removed

N\A

___

## `[3.0.1 2023-04-04]`

### Changes

- update `github-update` job to fix the `regex` to loop only branchs that starts with `release` or `hotfix`
- fix the issue #22 include `--on-failure DELETE` in the `sam-deploy` job.
- fix the issue #20 include a parameter `path` to job `invalidate-cache` with default value `/*`

### Added

N\A

### Removed

N\A

___

## `[3.0.0] - 2023-03-28`

### Changes

- changed the `eks-deploy` to target default repository `gitops`

  ```yaml
  - dft/eks-deploy:
      name: deploy-to-(live|qa)
      context: [DEFAULT, (LIVE|QA)]
  ```

  There are no need to pass the parameters `deployment_path` or even `gitops` to target the `gitops` repository.
  The default values of this job and the environments `LIVE QA DEFAULT` has the values needed to perform the deploy using only the context.
- updated `eks-promote` to target default repository `gitops`.

  ```yaml
  - dft/eks-promote:
      name: promote-to-live
      context: [DEFAULT]
  ```

  The `eks-promote` job will automatically get the `image.tag` from `gitops/apps/${COUNTRY}/${CIRCLE_PROJECT_REPONAME}/qa/kustomization.yaml` to replace in `gitops/apps/${COUNTRY}/${CIRCLE_PROJECT_REPONAME}/live/kustomization.yaml`. There are more variables to handle this job like:
  | parameter     | type     | description                                                |
  | :------------ | :------- | :--------------------------------------------------------- |
  | `app_name`    | `string` | Default is env `$CIRCLE_PROJECT_REPONAME`                  |
  | `origin_env`  | `string` | Default is `qa`, the folder name where to get `image.tag`  |
  | `destiny_env` | `string` | Default `live`, the folder name where to place `image.tag` |
  | `origin`      | `string` | Override all path creation to get the `image.tag` from     |
  | `destiny`     | `string` | Override all path creation to place the `image.tag`        |
- Changes `instana-notify` job, the parameter `service_name` to default `${CIRCLE_PROJECT_REPONAME}.${COUNTRY}.${ENV_SHORT}`
