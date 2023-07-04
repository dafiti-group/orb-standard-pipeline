# orb-standard-pipeline

## `[3.1.0 2023-06-21]`

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

  The `eks-promote` job will automatically get the `image.tag` from `gitops/apps/${COUNTRY}/${CIRCLECI_PROJECT_REPONAME}/qa/kustomization.yaml` to replace in `gitops/apps/${COUNTRY}/${CIRCLECI_PROJECT_REPONAME}/live/kustomization.yaml`. There are more variables to handle this job like:
  | parameter     | type     | description                                                |
  | :------------ | :------- | :--------------------------------------------------------- |
  | `app_name`    | `string` | Default is env `$CIRCLECI_PROJECT_REPONAME`                |
  | `origin_env`  | `string` | Default is `qa`, the folder name where to get `image.tag`  |
  | `destiny_env` | `string` | Default `live`, the folder name where to place `image.tag` |
  | `origin`      | `string` | Override all path creation to get the `image.tag` from     |
  | `destiny`     | `string` | Override all path creation to place the `image.tag`        |
- Changes `instana-notify` job, the parameter `service_name` to default `${CIRCLECI_PROJECT_REPONAME}.${COUNTRY}.${ENV_SHORT}`
