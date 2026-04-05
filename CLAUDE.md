# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of Helm charts published to GitHub Pages (`https://trankimtung.github.io/homemade-k8s`) via [helm/chart-releaser-action](https://github.com/helm/chart-releaser-action).

## Common commands

```bash
# Lint a chart
helm lint charts/<chart-name>

# Render templates locally
helm template <release-name> charts/<chart-name>

# Render with custom values
helm template <release-name> charts/<chart-name> -f my-values.yaml

# After editing library templates or changing dependencies
helm dependency update charts/<chart-name>
```

## How publishing works

1. A push to `main` touching `charts/**` triggers the release workflow.
2. Charts whose `version` in `Chart.yaml` changed since the last release are packaged and released.
3. **To release: bump `version` in `Chart.yaml` and push to `main`.** Nothing else is needed.

The `gh-pages` branch is managed entirely by the workflow — never commit to it manually.

## Library chart (`charts/common/`)

`charts/common/` is a `type: library` chart published alongside the application charts. Consumer charts depend on it via the published repo:

```yaml
dependencies:
  - name: common
    version: "0.1.0"
    repository: "https://trankimtung.github.io/homemade-k8s"
```

After editing any template in `charts/common/` you must:
1. Bump `version` in `charts/common/Chart.yaml`
2. Update the version constraint in the consumer chart's `Chart.yaml`
3. Run `helm dependency update charts/<chart-name>` to re-vendor the `charts/common-*.tgz` snapshot
4. Commit `Chart.lock` and `charts/common-*.tgz`

The tgz is a vendored snapshot — the release workflow does not run dependency update, so stale vendored files ship stale code.

## Two chart generations

**Legacy charts** (audiobookshelf, pihole, uptime-kuma): each has its own `_helpers.tpl` that re-implements `name`, `fullname`, `labels`, `selectorLabels` helpers, and individual template files per resource (`deployment.yaml`, `service.yaml`, `ingress.yaml`, `pvc.yaml`).

**Common-library charts** (navidrome): a single `components.yaml` delegates everything to the library:
```yaml
{{- include "navidrome.validate" . }}
{{- include "common.components" (dict "ctx" . "components" .Values.components) }}
```
All resources are driven entirely by `values.yaml` under a `components:` map — no per-resource template files needed. When migrating a legacy chart or writing a new one, use this pattern.

## `common.components` values schema

```yaml
components:
  <component-name>:          # key == fullname → "primary" (no name suffix on resources)
    deployments:
      <dep-key>:
        replicas: 1
        strategy: {type: Recreate}
        initContainers: []
        extraEnv: {}         # merged into all containers
        envFrom: []
        extraVolumes: []
        extraVolumeMounts: []
        containers:
          <container-key>:
            image: repo/name:tag@sha256:...
            imagePullPolicy: IfNotPresent
            args: []
            ports:
              <port-name>: {containerPort: 8080, protocol: TCP}
            uid: ""          # falls back to global.uid
            gid: ""          # falls back to global.gid
            securityContext: {...}
            env: {}
            extraEnv: {}
            envFrom: []
            probes:
              startup: {...}
              liveness: {...}
              readiness: {...}
            extraVolumeMounts: []
            resources: {...}
    services:
      <svc-key>:
        type: ClusterIP
        ports:
          - name: <port-name>
            port: 8080
    ingresses:
      <ingress-key>:
        enabled: false
        className: ""
        portName: <port-name>   # default backend port
        hosts: [example.com]
        paths:
          - path: /
            pathType: Prefix
            # serviceName: suffix   # optional: appended to fullname; defaults to ingress name
            # portName: override    # optional: overrides top-level portName
        tls: {enabled: false, secretName: ""}
    cm:
      <cm-key>:
        mountTo:
          <dep-key>: /mount/path   # only mounts into the named deployment
        data:
          filename.conf: |
            contents
    persistence:
      <pvc-key>:
        enabled: false
        existingClaim: ""
        mountTo:
          <dep-key>: /mount/path   # only mounts into the named deployment
        size: 1Gi
        accessMode: ReadWriteOnce
        storageClass: ""
```

## Resource naming rules (common library)

For a component whose key equals the release fullname ("primary"):
- Resources use just `fullname` when their own key also equals the component name
- Otherwise `fullname-<key>`

For a secondary component (key ≠ fullname):
- Base is `fullname-<component>`; resources follow the same key-matching rule from there

`app.kubernetes.io/component: <component-key>` is always added to selector labels so multiple components never cross-select pods.

## Chart conventions

- **Image tags**: Always pin to a digest (`image: repo/name:tag@sha256:...`).
- **Deployment strategy**: Always `Recreate` when PVCs use `ReadWriteOnce`.
- **Security context defaults**: `runAsNonRoot`, drop all capabilities, `seccompProfile: RuntimeDefault`. Add back only what is strictly required.
- **Probes**: Use `startupProbe` for slow-starting apps; keep liveness/readiness simple.
- **Validation**: Each chart's `_helpers.tpl` has a `<chart>.validate` template called at the top of the main template file. Fail fast with `{{- fail "message" }}`.
- **values.yaml comments**: Concise; link to upstream docs rather than duplicating option lists.
- **global**: Shared settings (`uid`, `gid`, `timezone`) live under `global:` so containers can reference them without repetition.
