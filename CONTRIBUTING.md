# Contributing

Thanks for helping improve the Terminus Helm chart. This repository contains
the chart only; bugs in the Terminus application itself belong in the
[Terminus project](https://github.com/usetrmnl/terminus).

## Before you start

- For anything larger than a small fix, open an issue first so we can agree on
  the approach.
- Security problems: do not open an issue. See [SECURITY.md](SECURITY.md).

## Development setup

You need [Docker](https://docs.docker.com/get-docker/), [k3d](https://k3d.io/#installation)
and [Helm](https://helm.sh/docs/intro/install/).

```bash
make run       # create a local k3d cluster and install the chart from your checkout
make status    # show pods
make logs      # follow web logs
make test      # run `helm test`
make destroy   # delete the cluster
```

`make run` installs from `charts/terminus`, so re-running it picks up your
edits. See the README for options (`PORT`, `HOST`, `K3S_IMAGE`).

## Making a change

1. Fork the repo and branch from `master`.
2. Edit the chart under `charts/terminus/`. Update `doc/helm.adoc` and
   `README.md` when you add or change values or behavior.
3. Bump `version` in `charts/terminus/Chart.yaml` (see below).
4. Check locally:

   ```bash
   helm lint charts/terminus -f charts/terminus/ci/default-values.yaml
   helm template terminus charts/terminus -f charts/terminus/ci/default-values.yaml
   ```

   The chart requires connection settings and an app secret, so lint and
   template need values like those in `charts/terminus/ci/`.
5. Open a pull request against `master` and fill in the template.

### Versioning

`ct lint` fails pull requests that change the chart without increasing
`version` in `Chart.yaml`. Use semantic versioning: patch for fixes, minor for
backward-compatible features or new values, major for breaking changes
(renamed or removed values, changed defaults that affect upgrades).

### CI

Pull requests run:

- **Lint**: `ct lint` (with yamllint and the chart schema) plus template
  rendering.
- **E2E**: installs the chart on a kind cluster and runs the tests under
  `test/e2e/`.

Both must pass. Releases are cut from `v*` tags by the maintainer.

## Guidelines

- Keep changes focused; one concern per pull request.
- New features should be opt-in with defaults that keep existing installs
  working.
- Never commit real credentials. Values in `local/` and `ci/` are throwaway.
- Pin any new GitHub Action to a full commit SHA with a version comment.
- Write commit messages for humans, follow the [Git commit anatomy](https://alchemists.io/articles/git_commit_anatomy).


## License

By contributing you agree that your contributions are licensed under the
[MIT License](LICENSE).
