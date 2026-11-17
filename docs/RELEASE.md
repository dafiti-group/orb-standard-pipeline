# How the orb is published (release process)

This orb is published to the CircleCI registry as `dafiti-group/orb-standard-pipeline`.
There are two kinds of versions:

| Type | Example | When it is published | Used for |
|---|---|---|---|
| **dev** | `@dev:<commit-sha>`, `@dev:alpha` | Every push, on any branch | Testing a change before merging. Expires after 90 days |
| **production** | `@3.11.8` | Only when a `vX.Y.Z` git tag is pushed | What projects use |

**Merging into `main` does not publish a production version by itself.** What publishes it is the
`vX.Y.Z` tag, and on `main` that tag is created automatically by the `auto-tag` job (details below).

## Pipeline flow

The repo uses CircleCI [dynamic config](https://circleci.com/docs/dynamic-config/) (`setup: true`),
so two config files run one after the other:

```text
push (branch or tag)
 └─ .circleci/config.yml  (lint-pack)
     ├─ orb-tools/lint, orb-tools/pack, orb-tools/review, shellcheck/check
     ├─ orb-tools/publish        -> publishes @dev:<sha>
     └─ orb-tools/continue       -> starts .circleci/test-deploy.yml
         └─ .circleci/test-deploy.yml  (test-deploy, uses @dev:<sha>)
             ├─ command-tests        -> smoke test of a few orb commands
             ├─ orb-tools/pack
             ├─ auto-tag             -> ONLY on main: creates and pushes the vX.Y.Z tag
             └─ orb-tools/publish    -> ONLY on vX.Y.Z tags: publishes @X.Y.Z (production)
```

Merging a version bump into `main` produces two pipelines:

1. **Pipeline on `main`**: publishes `@dev:<sha>`, runs the tests, and `auto-tag` creates the `vX.Y.Z` tag.
2. **Pipeline on the `vX.Y.Z` tag** (triggered by the tag push): publishes `@X.Y.Z` to production.

## `auto-tag` job

Script: [`.circleci/scripts/auto-tag.sh`](../.circleci/scripts/auto-tag.sh). It runs only on `main`,
after `command-tests` and `orb-tools/pack` pass, using the `DEFAULT` context (`GITHUB_TOKEN`).

- The version comes from the **first entry** of [`CHANGELOG.md`](../CHANGELOG.md) (a ``## `[X.Y.Z YYYY-MM-DD]` `` heading).
- **The tag already exists**: the job does nothing and succeeds. This covers PRs that change docs or CI
  without bumping the version, so they don't generate a release.
- **The version is lower than the latest tag**: the job fails, because the bump is wrong.
- **Some file in `src/examples` doesn't reference the new version**: the job fails and lists the files.
- If every check passes, it creates an annotated `vX.Y.Z` tag on the merged commit and pushes it.

## How to release a new version (step by step)

1. Create your branch from `main` following the convention: `hotfix/vX.Y.Z/<description>`, `feature/...` or `release/...`.
2. Make the change in `src/`.
3. Test with the dev version: after the push, use `dafiti-group/orb-standard-pipeline@dev:<commit-sha>`
   in a consumer project (or run `make dev` locally, which publishes `@dev:first`).
4. **Bump the version** in the same PR, following [semver](https://semver.org/):
   - add a new entry **at the top** of `CHANGELOG.md`: ``## `[X.Y.Z YYYY-MM-DD]` ``;
   - update every `src/examples/*.yml` to `dafiti-group/orb-standard-pipeline@X.Y.Z`
     (e.g. `grep -rl "orb-standard-pipeline@OLD" src/examples | xargs sed -i '' 's/@OLD/@X.Y.Z/'`).
5. Open the PR against `main` using the template and fill in "New release version candidate".
6. Merge. `auto-tag` creates the tag and the tag pipeline publishes the version. Check it with
   `circleci orb info dafiti-group/orb-standard-pipeline | grep Latest`.

## Manual release (fallback)

If `auto-tag` fails, or you need to tag a specific commit, create the tag yourself:

```sh
git checkout main && git pull
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

The tag must follow exactly `vX.Y.Z` (regex `^v[0-9]+\.[0-9]+\.[0-9]+$`), or the production publish won't run.
Production versions can't be overwritten: to fix a release, publish a new version.

## Troubleshooting

- **The merge went in but no version was published**: check whether `CHANGELOG.md` was bumped. Without a bump,
  `auto-tag` skips on purpose.
- **`auto-tag` failed on outdated examples**: open a follow-up PR bumping the files it lists.
- **`auto-tag` failed to push**: check that the `GITHUB_TOKEN` in the `DEFAULT` context has write access
  (`contents: write`) to this repo and isn't blocked by a tag protection rule.
