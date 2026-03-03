# Contributing to OKD Operator Pipeline

## Prerequisites

- Git, Podman, OpenShift CLI (`oc`)
- `operator-sdk`, `kustomize`, `yq` (v4+), `jq`, `skopeo`

## Getting Started

Clone with submodules:
```bash
git clone --recursive https://github.com/yourusername/okd-operator-pipeline.git
cd okd-operator-pipeline
```

Or initialize submodules in existing clone:
```bash
git submodule update --init --recursive
```

## Build Script Structure

All operator build scripts follow a standardized structure with 6 core functions:

1. **`init()`** - Initialize git submodules (required)
2. **`deinit()`** - Reset git submodules (required)
3. **`update()`** - Update submodules to latest upstream commits (optional, not run by default)
4. **`build_containers()`** - Build all container images (required)
5. **`push_containers()`** - Push all container images (required)
6. **`build_bundle()`** - Build AND push bundle(s) (required)

### Template

```bash
#!/bin/bash

# Configuration and variable setup
MAJOR=1 # Optional: if operator not locked to OpenShift platform versioning
MINOR=2 # Optional: same as above
NAMESPACE="operator-name"
source ../common.sh

# Image definitions
export IMG_OPERATOR="${REGISTRY}/operator:${OCP_DATE}"
IMG_BUNDLE="${REGISTRY}/operator-bundle:${OCP_DATE}"

## Functions

init() {
    submodule_initialize <repo> <branch>
}

deinit() {
    submodule_reset <repo> <branch>
}

update() {
    submodule_update <repo> <branch> <github-url>
}

build_containers() {
    podman build -t $IMG_OPERATOR -f operator.Containerfile .
}

push_containers() {
    push_all_images  # Or manually push each image
}

build_bundle() {
    pushd operator
    yq e -i "..." config/...  # Update manifests/CSV
    make bundle ...            # Generate bundle
    podman build -t $IMG_BUNDLE -f bundle.Dockerfile .
    podman push $IMG_BUNDLE
    popd
}

## Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Usage

```bash
# Full build (runs all steps)
./build.sh

# Individual steps
./build.sh init build_containers              # Build without pushing
./build.sh build_containers push_containers   # Skip init/deinit
./build.sh build_bundle                       # Only rebuild bundle

# Update submodules (not run by default)
./build.sh update

# Source and run functions interactively
source build.sh
init
build_containers
# ... testing ...
deinit
```

### Design Rationale

**Bundle build/push combined:** Some operators have multiple bundles with dependencies (e.g., `cluster-logging` has `loki-operator-bundle` → `operator-bundle`). operator-sdk checks bundle dependencies on the remote registry, requiring consecutive build-and-push operations.

**Sourceable scripts:** Allows running individual functions for iterative development, testing specific steps, and debugging.

**Separate init/deinit:** Provides explicit submodule control, clearer debugging flow, and ability to skip initialization when submodules are already set up.

**update() not run by default:** Prevents unexpected upstream changes. Must be called explicitly: `./build.sh update`

### Variable Naming

- `IMG_<COMPONENT>`: Container image references (export operand images)
- `IMG_BUNDLE_<COMPONENT>`: Bundle image references
- `REGISTRY`: Base registry path
- `OCP_DATE`: Version tags (e.g., "4.20.0-2026-03-03-120000")
- `OCP_SHORT`: Short version (e.g., "4.20")

## Adding a New Operator

1. **Create directory and add submodules:**
   ```bash
   mkdir <operator-name>
   cd <operator-name>
   git submodule add -b release-X.Y https://github.com/upstream/operator.git operator
   ```

2. **Create build.sh** using template above

3. **Create Containerfiles** for each component

4. **Test the build:**
   ```bash
   export NAMESPACE="operator-name"
   ./build.sh
   ```

## Updating an Existing Operator

### To a New Release Branch

Updating to a new release branch either needs to be done as a whole for OpenShift versioned projects, or by changing
the MAJOR/MINOR version environment variable overrides in each operator's build script.

Once that is done, `build.sh update` can be run to update all submodules to the new release branch. After updating, it's
worth running `build.sh init` to ensure that any patches are applied correctly. Otherwise if you get a patch conflict, 
you'll need to manually resolve conflicts in the specific submodule and run `git am --continue` once done. From there 
you need to run `git format patch HEAD~1 --stdout > <patch-file>` to get the patch file for the submodule, and place 
that into the `patches/` directory.

### Adding Patches

```bash
# Make changes in submodule, then:
cd <operator-name>/operator
# If an patch already exists, use:
git add .
git commit --amend --no-edit
git format-patch HEAD~1 --stdout > ../patches/<submodule_name>.patch
```
The patch path is `<operator>/patches/<submodule_name>.patch`

Patches are automatically applied by `submodule_initialize()`.

## Common Build Functions

From `common.sh`:

**Submodule Management:**
- `submodule_exists <path>` - Check if submodule exists
- `submodule_initialize <path> <branch>` - Initialize and patch submodule
- `submodule_update <path> <branch> <url>` - Update to latest upstream
- `submodule_reset <path> <branch>` - Clean and reset submodule

**Image Handling:**
- `push_all_images` - Push all `IMG_*` variables to registry
- `convert_all_images_to_digest` - Convert image tags to digest format
- `get_payload_component <name>` - Extract component image from OKD release

## Testing

### Local Build Test

```bash
export BASE_REGISTRY="localhost:5000/test"
export NAMESPACE="test-operator"
cd <operator-name>
./build.sh
podman images | grep test-operator
```

### Testing Individual Steps

```bash
cd <operator-name>
source build.sh

init
build_containers
podman images  # Inspect/test containers
push_containers
build_bundle
deinit
```

### Bundle Validation

```bash
operator-sdk bundle validate --verbose ./bundle
```

## Git Workflow

### Branch Strategy

- `main` - Stable release branch
- `release-4.XX` - Version-specific branches
- `feature/<description>` - Feature branches
- `fix/<description>` - Fix branches


Examples:
- `[cert-manager] Update to 1.18`
- `[sr-iov] Fix build script and submodule`
- `[common] Add digest conversion function`

## Getting Help

- Open an issue for bugs or feature requests
- Start a discussion for questions
- Review existing PRs for examples
