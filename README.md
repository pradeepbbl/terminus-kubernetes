# terminus-kubernetes

Kubernetes deployment for [Terminus](https://github.com/usetrmnl/terminus): Helm chart with optional bundled Postgres/Valkey, Ingress/Gateway API and Vault support.

> [!TIP]
> ## 🚀 Try it locally before deploying to your cluster
>
> Not sure the chart fits your setup yet? Run the whole stack (Terminus, PostgreSQL, Valkey and an Ingress) on a throwaway Kubernetes cluster inside Docker first. Nothing touches your real cluster, and when you're happy with it, move on to [Quick start](#quick-start) to deploy for real.
>
> ```bash
> git clone https://github.com/pradeepbbl/terminus-kubernetes.git
> cd terminus-kubernetes
>
> make run       # create the local cluster and install Terminus
> make stop      # stop the cluster, keeping your data
> make destroy   # delete the cluster and all its data
> ```
>
> Then open **http://terminus.localtest.me:8080**. The first run pulls several images and takes a few minutes; `make run` again resumes a stopped cluster and upgrades the release. `make run` installs the chart from your checkout, so local edits to `charts/terminus` are picked up on the next run, which also makes it a quick way to try chart changes.
>
> **Requires:** [Docker](https://docs.docker.com/get-docker/), [k3d](https://k3d.io/#installation) and [Helm](https://helm.sh/docs/intro/install/). k3d runs [k3s](https://k3s.io/) in Docker, which includes the Traefik ingress controller, so there is nothing else to set up.
>
> - `terminus.localtest.me` is public wildcard DNS for `127.0.0.1`, so no `/etc/hosts` edit is needed.
> - Change the port or hostname with `make run PORT=9090 HOST=trmnl.localtest.me`. To change `PORT` on an existing cluster, `make destroy` first.
> - `make status`, `make logs` and `make test` show the pods, follow the web logs and run the chart's `helm test`.
> - k3d adds a `k3d-terminus` entry to your kubeconfig and, by default, makes it the current `kubectl` context. The Makefile always targets it explicitly, but run `kubectl config use-context <your-context>` afterwards if you use `kubectl` against another cluster.
> - On a host using cgroup v1 (check with `docker info | grep -i cgroup`), the Makefile automatically uses k3s 1.34, since newer k3s kubelets refuse to start there. Override with `K3S_IMAGE=rancher/k3s:<tag>`.
> - If `make run` hangs with `connection to the server 127.0.0.1:6443 was refused`, the cluster never became healthy: run `make destroy`, then `make run` again.
> - Credentials in `local/values.yaml` are throwaway values for local use only.

## Layout

```
charts/terminus/     Helm chart
doc/helm.adoc        Full chart documentation (values, Vault, Istio, upgrades)
.github/workflows/   lint.yml, e2e.yml (PR/push) and release.yml (tag)
ct.yaml              chart-testing config
Makefile             local run/stop/destroy on k3d
local/values.yaml    values used by `make run`
test/e2e/            values and manifests for the kind-based end-to-end tests
```

## Quick start

```bash
helm install terminus ./charts/terminus \
  --namespace terminus --create-namespace \
  --set config.apiUri="https://terminus.example.com" \
  --set secrets.databaseUrl="postgres://user:password@postgres-host:5432/terminus" \
  --set secrets.keyvalueUrl="redis://:password@valkey-host:6379/0" \
  --set secrets.appSecret="$(openssl rand -hex 64)"
```

Or run everything in-cluster with the bundled database and key-value store (single instance, no backups — small setups only):

```bash
helm install terminus ./charts/terminus \
  --namespace terminus --create-namespace \
  --set config.apiUri="https://terminus.example.com" \
  --set migrate.enabled=false \
  --set database.enabled=true --set database.auth.password="$(openssl rand -hex 16)" \
  --set keyvalue.enabled=true \
  --set secrets.appSecret="$(openssl rand -hex 64)"
```

See [doc/helm.adoc](doc/helm.adoc) for the full guide.

## Development

```bash
helm lint charts/terminus -f charts/terminus/ci/default-values.yaml
helm template terminus charts/terminus -f charts/terminus/ci/default-values.yaml
```

End-to-end test against a local [kind](https://kind.sigs.k8s.io/) cluster, the same steps CI runs:

```bash
kind create cluster
helm install terminus charts/terminus -n terminus --create-namespace \
  -f test/e2e/bundled-values.yaml --wait --timeout 8m
helm test terminus -n terminus --logs
```

## Releasing

1. Bump `version` in `charts/terminus/Chart.yaml` in a PR (CI requires the bump). Bump `appVersion` too if the default Terminus image tag should change.
2. After merge, tag the merge commit with the same version: `git tag v0.2.0 && git push origin v0.2.0`.

The tag triggers lint and the e2e test, checks the tag matches `Chart.yaml`, pushes the chart to `oci://ghcr.io/pradeepbbl/charts/terminus` and creates a GitHub release with the packaged chart attached. The package on ghcr.io must be set to public once, after the first push, for anonymous `helm install`.

## License

See [LICENSE](LICENSE).
