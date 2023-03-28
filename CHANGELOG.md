# org-standard-pipeline

## `[3.0.0] - 2023-03-28`

### Changes

- changed the `eks-deploy` to target default repository `gitops`
  ```yaml
  - dft/eks-deploy:
      name: deploy-to-(live|qa)
      context: [DEFAULT, (LIVE|QA)]
  ```
  There are no need to pass the parameters `deployment_path` or even `gitops` to garget the `gitops` repository.
  The default values of this job and the environments `LIVE QA DEFAULT` has the values needed to perform the deploy using only the context.
- updated `eks-promote` to target default repository `gitops`.
  ```yaml
  - dft/eks-promote:
      name: promote-to-live
      context: [DEFAULT]
  ```
  The `eks-promote` job will automatically get the `image.tag` from `gitops/apps/${COUNTRY}/${CIRCLECI_PROJECT_REPONAME}/qa/kustomization.yaml` to replace in `gitops/apps/${COUNTRY}/${CIRCLECI_PROJECT_REPONAME}/live/kustomization.yaml`. There are more variables to handle this job like:
  |parameter|type|description|
  |:-|:-|:-|
  |`app_name`|`string`|Default is env `$CIRCLECI_PROJECT_REPONAME`|
  |`origin_env`|`string`|Default is `qa`, the folder name where to get `image.tag`|
  |`destiny_env`|`string`|Default `live`, the folder name where to place `image.tag`|
  |`origin`|`string`|Override all path creation to get the `image.tag` from|
  |`destiny`|`string`|Override all path creation to place the `image.tag`|
- Changes `instana-notify` job, the parameter `service_name` to default `${CIRCLECI_PROJECT_REPONAME}.${COUNTRY}.${ENV_SHORT}`
