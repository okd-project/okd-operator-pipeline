# AGENTS.md — OKD Operator Pipeline

This document is written for AI agents. For human-oriented docs see `BUILDING.md` and `CONTRIBUTING.md`.

## Repo Overview

This repository builds and packages upstream Kubernetes operators for **OKD** (the community OpenShift distribution). Each top-level directory is one operator. The build system is pure bash, sharing utilities from `common.sh`.

**OKD versioning:** `OKD_VERSION` in `common.sh` (e.g. `4.21.0-okd-scos.10`) drives everything. `OCP_SHORT` = `MAJOR.MINOR` (e.g. `4.21`). Most operators track `release-${OCP_SHORT}` branches. Some operators use independent versioning and override `MAJOR`/`MINOR` in their `build.sh`.

## Directory Layout

```
okd-operator-pipeline/
├── common.sh               # Shared env vars and bash functions (source of truth)
├── BUILDING.md             # Human build guide
├── CONTRIBUTING.md         # Dev conventions including build script template
├── .gitmodules             # All submodule registrations (100+ submodules)
├── metallb/                # Example: OKD-versioned operator
│   ├── build.sh            # NAMESPACE="metallb"; sources ../common.sh
│   ├── frr/                # Git submodule (branch: release-4.21)
│   ├── metallb/            # Git submodule (branch: release-4.21)
│   ├── operator/           # Git submodule (branch: release-4.21)
│   ├── frr.Containerfile
│   ├── metallb.Containerfile
│   ├── operator.Containerfile
│   └── patches/
│       └── operator.patch  # Applied automatically by submodule_initialize()
├── cluster-logging/        # Example: independently-versioned (MAJOR=6 MINOR=3)
├── service-mesh/           # Example: independently-versioned (MAJOR=3 MINOR=0)
├── gitops/                 # Example: independently-versioned (MAJOR=1 MINOR=19)
└── ...                     # acm, cert-manager, data-foundation, external-secrets,
                            # ingress-node-firewall, local-storage, lvms, metallb,
                            # multicluster-engine, network-observability, nmstate,
                            # node-feature-discovery, oadp, pf-status-relay, sr-iov,
                            # vertical-pod-autoscaler, web-terminal, cluster-observability
```

## Build System

### Key Variables (set by `common.sh`)

| Variable | Example | Source |
|---|---|---|
| `NAMESPACE` | `metallb` | Set in `build.sh` before `source ../common.sh` |
| `BASE_REGISTRY` | `quay.io/okderators` | Env override or default |
| `REGISTRY` | `quay.io/okderators/metallb` | `${BASE_REGISTRY}/${NAMESPACE}` |
| `OKD_VERSION` | `4.21.0-okd-scos.10` | Env override or default |
| `OCP_SHORT` | `4.21` | Derived from `MAJOR.MINOR` |
| `OCP_DATE` | `4.21.0-2026-05-12-104500` | Used for all image tags |
| `DATE` | `2026-05-12-104500` | `$(date +%Y-%m-%d-%H%M%S)` or env override |

### `build.sh` Structure

Every operator's `build.sh` follows the same pattern:

```bash
NAMESPACE="operator-name"
# MAJOR=X  # Only if not using OKD platform versioning
# MINOR=Y
source ../common.sh

export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
export IMG_COMPONENT="${REGISTRY}/component:${OCP_DATE}"
IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

init()             { submodule_initialize <repo> <branch>; ... }
deinit()           { submodule_reset <repo> <branch>; ... }
update()           { submodule_update <repo> <branch> <url>; ... }
build_containers() { podman build -t "${IMG_OPERATOR}" -f operator.Containerfile .; ... }
push_containers()  { podman push "${IMG_OPERATOR}"; ... }  # or push_all_images
build_bundle()     { # yq edits to CSV/manifests, then operator-sdk generate bundle, podman build+push }

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi
```

### Execution

```bash
./build.sh                              # All steps: init → build_containers → push_containers → build_bundle → deinit
./build.sh init build_containers        # Selected steps in order
./build.sh update                       # Update submodules (never run by default)
source build.sh && init && build_containers  # Interactive / debug
```

**`update()` is never run automatically.** It must be called explicitly.

### Common Utility Functions (from `common.sh`)

- `submodule_initialize <path> <branch>` — init submodule + apply patch from `patches/<path>.patch`
- `submodule_reset <path> <branch>` — clean and hard-reset to recorded commit
- `submodule_update <path> <branch> <url>` — fetch latest from `origin/<branch>`
- `push_all_images` — pushes all exported `IMG_*` vars (skips `IMG_BUNDLE*`)
- `convert_all_images_to_digest` — rewrites `IMG_*` vars to `name@sha256:...` using skopeo
- `get_payload_component <name>` — extracts a component image from the OKD release payload via `oc adm release info`

## Updating an Operator

### OKD-versioned operators (most operators)

1. Update `.gitmodules` — change `branch = release-4.20` → `branch = release-4.21` for each submodule in the operator
2. Run `./build.sh update` from the operator directory to pull new commits
3. **Compare upstream Dockerfiles** — see [Comparing with upstream Dockerfiles](#comparing-with-upstream-dockerfiles) below
4. Run `./build.sh init` to verify patches still apply cleanly
5. Run `./build.sh init build_containers` to verify the operator compiles — a clean patch does not guarantee a successful build (upstream Go or dependency changes can break compilation)

### Independently-versioned operators (cluster-logging, service-mesh, gitops, etc.)

1. Update `MAJOR`/`MINOR` in the operator's `build.sh`
2. Update submodule branch refs in `.gitmodules` to match the new version
3. **Compare upstream Dockerfiles** — see [Comparing with upstream Dockerfiles](#comparing-with-upstream-dockerfiles) below
4. Run `./build.sh update && ./build.sh init` to verify patches apply
5. Run `./build.sh init build_containers` to verify the operator compiles

### Comparing with upstream Dockerfiles

Red Hat publishes the Dockerfiles used to build each operator component in the container catalog. Before finalising an operator update, fetch the upstream Dockerfiles for the new version and compare them against the `.Containerfile` files that live directly in the operator directory (not inside submodule directories).

```bash
# From the repo root — replace <operator> and <version> as appropriate
./scripts/rhcatalog.sh dump-containerfiles <operator> v<MAJOR>.<MINOR>.0 /tmp/<operator>-upstream/

# Example:
./scripts/rhcatalog.sh dump-containerfiles metallb v4.21.0 /tmp/metallb-upstream/
./scripts/rhcatalog.sh dump-containerfiles sr-iov  v4.21.0 /tmp/sr-iov-upstream/
```

Then diff each dumped `.Dockerfile` against the corresponding `.Containerfile` in the operator directory. The mapping is not systematic — use the component name in the filename as a guide (e.g. `metallb-rhel9-operator.Dockerfile` → `operator.Containerfile`, `frr-rhel9.Dockerfile` → `frr.Containerfile`).

**What to ignore in the upstream Dockerfile — these are RH build-system artefacts that OKD intentionally omits:**

| Pattern | Reason to ignore |
|---|---|
| `# Start Konflux-specific steps` … `# End Konflux-specific steps` blocks | Konflux CI cache priming; not needed outside RH infra |
| `ENV __doozer=update …` and `ENV __doozer=merge …` lines | Doozer build metadata injected by ART tooling |
| `ENV ART_BUILD_ENGINE=`, `ENV ART_BUILD_DEPS_METHOD=`, `ENV ART_BUILD_NETWORK=`, `ENV ART_BUILD_DEPS_MODE=` | ART/Konflux build flags |
| `RUN go clean -cache \|\| true` | Konflux cache-busting side effect |
| `LABEL` directives | Generated automatically during the RH build pipeline |
| `FROM brew.registry.redhat.io/…` or `FROM quay.io/redhat-user-workloads/…` base images | RH-internal registries; OKD uses `registry.access.redhat.com/ubi9/go-toolset`, `quay.io/centos/centos:stream9`, or similar public equivalents |

**What to act on — these indicate real changes that may need to be reflected in the OKD Containerfile:**

- Changes to non-FROM build instructions: new `COPY`, `RUN`, `WORKDIR` steps, or changed commands
- New packages added (`dnf install`, `yum install`)
- Changed binary output paths or names in `COPY --from=builder` lines
- New runtime `ENV` variables (not doozer/ART metadata)
- `ENTRYPOINT` or `CMD` changes
- New build stages or stage dependencies
- Changes to the type/version of base image (e.g. builder switching from Go 1.21 to Go 1.24 — update the OKD equivalent accordingly)

### Implementing `build_bundle()`

**Standard flow** — every `build_bundle()` should follow this order:

1. Convert images to digests (if the Makefile lacks `--use-image-digests` support — see below)
2. Update every source file that carries image references with the new values
3. Call `make bundle` (or the equivalent Makefile target) — **never** call `operator-sdk generate bundle` directly; the Makefile applies custom CSV fixups that a direct call skips
4. Call `make bundle-build` (or `podman build`) to build the bundle image and push it

**`make bundle` owns `spec.relatedImages`** — operator-sdk auto-populates `spec.relatedImages`
from every `RELATED_IMAGE_*` env var it finds in the deployment spec of the generated CSV.
Do **not** replace this list with `=` after bundle generation; that overwrites entries
operator-sdk correctly added and hides any images you failed to pre-set.
If extra images genuinely need to be added that operator-sdk cannot detect from the deployment
spec, append them with `+=`:

```bash
export EXTRA_IMAGES="..."
yq e -i '.spec.relatedImages += env(EXTRA_IMAGES)' "${CSV_PATH}"
```

**Digest conversion** — when the operator's Makefile does not accept `BUNDLE_METADATA_OPTS` or
`--use-image-digests`, call `convert_all_images_to_digest` before updating any source files.
All `IMG_*` vars will then hold `registry/image@sha256:…` digests, and they must be written into
the source files before `make bundle` runs.

**Preserved env vars in committed bundle** — operators that call `make bundle --overwrite` merge
the new kustomize output with the existing committed bundle. Deployment env vars that appear in
the committed bundle but are absent from `config/manager/manager.yaml` (or wherever kustomize
reads) are silently **preserved from the existing bundle unchanged**. If those env vars reference
images you rebuild for OKD, patch them in the committed bundle CSV *before* calling `make bundle`:

```bash
# Replace upstream digests with OKD images in the bundle CSV deployment spec
sed -i -E "s|upstream.registry/image@sha256:[a-f0-9]+|${IMG_REPLACEMENT}|g" "${CSV_PATH}"
```

This ensures `make bundle` generates `spec.relatedImages` entirely from OKD images rather than a
mix of OKD and upstream.

### Handling patch conflicts

If `./build.sh init` fails because a patch no longer applies cleanly:

1. Manually resolve conflicts in the submodule directory
2. `git am --continue` inside the submodule
3. Regenerate the patch: `git format-patch HEAD~1 --stdout > ../patches/<submodule-name>.patch`

### Amending an existing patch

```bash
cd <operator>/<submodule>
# make your changes
git add .
git commit --amend --no-edit
git format-patch HEAD~1 --stdout > ../patches/<submodule-name>.patch
```

Patches are stored at `<operator>/patches/<submodule-name>.patch` and applied automatically by `submodule_initialize`.

## Building

### Prerequisites

`bash`, `git`, `podman`, `oc`, `operator-sdk`, `kustomize`, `yq` (v4+), `jq`, `skopeo`

**Do not clone recursively.** The build scripts initialize submodules on demand.

### Full build

```bash
export BASE_REGISTRY="quay.io/myusername"
cd metallb
./build.sh
```

### Partial / iterative build

```bash
# Lock DATE so image tags stay consistent across separate steps
export DATE="$(date +%Y-%m-%d-%H%M%S)"
export BASE_REGISTRY="quay.io/myusername"

cd metallb
./build.sh init build_containers   # Build locally without pushing
./build.sh push_containers         # Push previously built images
./build.sh build_bundle            # Rebuild bundle only
```

`DATE` must remain constant across steps in the same session — it is baked into all image tags.

## Deploying

After a successful build, the bundle image URL is printed. Deploy it with:

```bash
operator-sdk run bundle <bundle-image-url>
```

Verify the installation:

```bash
oc get pods -n <operator-namespace>
oc get csv -A | grep <package-name>
```

Remove the operator:

```bash
operator-sdk cleanup <package-name>
```

## Conventions and Gotchas

- **`IMG_*` naming:** operand images use `IMG_<COMPONENT>` (exported); bundle images use `IMG_BUNDLE` or `IMG_BUNDLE_<NAME>` (not exported, not pushed by `push_all_images`)
- **`push_all_images`** skips any variable starting with `IMG_BUNDLE` and any image not prefixed with `$REGISTRY`
- **`bundle.Dockerfile`** is regenerated by `operator-sdk` during `build_bundle`; the existing one is renamed to `bundle.Dockerfile_orig` temporarily
- **Multiple bundles:** operators like `cluster-logging` build and push bundles in dependency order (loki-operator-bundle must be pushed before operator-bundle) because `operator-sdk` checks the remote registry for dependencies
- **`get_payload_component`** requires an active `oc` login and calls `oc adm release info` on `quay.io/okd/scos-release:${OKD_VERSION}` — this runs at script source time, not lazily
- **Quay.io 403 errors** on first push to a new repository are transient; re-running `push_containers` resolves them
- **Sourceable scripts:** `source build.sh` works for interactive debugging; functions can then be called individually without re-initializing submodules
- **Check that the directory you're in is a submodule**: If it is, the change has to be made into a patch, or alternatively a `yq` or `sed` edit from the `build.sh` script.