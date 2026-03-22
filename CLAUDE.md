# CLAUDE.md

## What this repo is

A collection of Helm charts published to:
- **GitHub Pages** (Helm HTTP repo) via [helm/chart-releaser-action](https://github.com/helm/chart-releaser-action)

## Project structure

```
charts/           # One subdirectory per Helm chart
.github/
  workflows/
    release-charts.yaml  # Packages and publishes charts on push to main
```

## Common commands

```bash
# Lint a chart
helm lint charts/<chart-name>

# Render templates locally (dry-run)
helm template <release-name> charts/<chart-name>

# Render with custom values
helm template <release-name> charts/<chart-name> -f my-values.yaml
```

## How publishing works

1. A push to `main` that touches `charts/**` triggers the release workflow.
2. The workflow detects charts whose `version` in `Chart.yaml` has changed since the last release.
3. Changed charts are packaged, a GitHub Release is created for each, `index.yaml` on the `gh-pages` branch is updated, and the chart is pushed to `ghcr.io/<owner>/charts`.
4. **To release a new chart version: bump `version` in `Chart.yaml` and push to `main`.** Nothing else is needed.

The `gh-pages` branch is managed entirely by the workflow — never commit to it manually.

## Adding a new chart

Place it under `charts/<chart-name>/` following standard Helm chart layout. The releaser picks it up automatically on the next push.

## Chart conventions used in this repo

- Common labels are defined in `_helpers.tpl` (`navidrome.labels`, `navidrome.selectorLabels`).
- Input validation (fail-fast) lives in `navidrome.validate` inside `_helpers.tpl`, called from `deployment.yaml`.
- `extraEnv`, `envFrom`, `extraVolumes`, `extraVolumeMounts` are standard escape hatches included in each chart.
- Security context defaults: `runAsNonRoot`, drop all capabilities, `seccompProfile: RuntimeDefault`.
- Use a `startupProbe` for slow-starting apps instead of inflating `initialDelaySeconds` on liveness/readiness probes.
- Each chart has a `Chart.yaml` with metadata and a `values.yaml` with default configuration.
- Keep comments in `values.yaml` concise and focused.