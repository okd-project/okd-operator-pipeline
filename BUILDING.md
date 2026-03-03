# Building and Deploying Operators

This guide explains how to build operator images and bundles from source, push them to a custom registry, and deploy 
them to an OKD cluster.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Building Operators](#building-operators)
- [Deploying to a Cluster](#deploying-to-a-cluster)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Ensure you have the following tools installed:

- **bash** - Shell for running build scripts
- **git** - Version control with submodule support
- **podman** - Container build and push operations
- **oc** - OpenShift CLI tool for cluster operations
- **operator-sdk** - Operator bundle management and deployment
- **kustomize** - Kubernetes manifest customization
- **yq** - YAML processor for manifest manipulation
- **jq** - JSON processor for parsing release info
- **skopeo** - Image inspection and copying

## Environment Setup

### Clone Repository

1. Clone the repository and navigate to the operator directory you want to build:

```bash
git clone https://github.com/okd-project/okd-operator-pipeline.git
```

> [!IMPORTANT]
> Do not clone the repository recursively. You will be waiting for a long time due to the large number of submodules.
> The build scripts will automatically initialize and update submodules during the build process.

### Custom Registry Configuration

To push images to your own container registry, set the `BASE_REGISTRY` variable:

```bash
# Example: Custom Quay.io namespace
export BASE_REGISTRY="quay.io/myusername"

# Example: Private registry
export BASE_REGISTRY="registry.example.com/okd-operators"

# Example: Local registry
export BASE_REGISTRY="localhost:5000/operators"
```

Images will be pushed to `${BASE_REGISTRY}/<namespace>/<image-name>:<version>`.

> [!IMPORTANT]
> Ensure you're authenticated to your registry before building.

### Optional Variables

```bash
# Target OKD version (default: 4.20.0-okd-scos.6)
export OKD_VERSION="4.20.0-okd-scos.6"

# Operator channel (default: alpha)
export CHANNEL="stable"
export DEFAULT_CHANNEL="stable"

# Custom build date (default: current timestamp)
export DATE="2026-03-03-120000"
```

## Building Operators

### Quick Start

The simplest way to build an operator:

```bash
# 1. Navigate to operator directory you want to build
cd metallb

# 4. Run the full build
BASE_REGISTRY="quay.io/myusername" ./build.sh
```

This will execute all build steps in order:
1. **init** - Initialize git submodules
2. **build_containers** - Build all container images
3. **push_containers** - Push images to registry
4. **build_bundle** - Generate, build, and push operator bundle
5. **deinit** - Reset git submodules

### Step-by-Step Build Process

You can run individual build steps by passing function names as arguments:

```bash
export DATE="$(date +%Y-%m-%d-%H%M%S)"

# Initialize submodules only
./build.sh init

# Build containers without pushing
./build.sh init build_containers

# Push pre-built containers
./build.sh push_containers

# Rebuild and push only the bundle
./build.sh build_bundle

# Run specific steps in sequence
./build.sh init build_containers push_containers build_bundle deinit
```

> [!WARNING]
> Running the build_containers, push_containers, and build_bundle functions will not work separately since they rely 
> on the build `DATE` variable generated at runtime.

### Common Build Workflows

### Updating Submodules to Latest Upstream

The `update()` function fetches the latest commits from upstream repositories:

```bash
# Update submodules to latest upstream commits
./build.sh update

# Then rebuild everything
./build.sh
```

> [!NOTE]
> The `update()` function is NOT run by default with `./build.sh`. You must call it explicitly.

## Deploying to a Cluster

### Using operator-sdk run bundle

The `operator-sdk run bundle` command is the simplest way to install your operator bundle directly from a registry.

#### Basic Deployment

```bash
# 1. Build and push your operator
cd metallb
BASE_REGISTRY="quay.io/myusername" ./build.sh

# 2. Deploy to cluster using operator-sdk
operator-sdk run bundle <bundle-image-url>
```

#### Verifying Deployment

After running the bundle, verify the operator is installed:

```bash
# Check operator pods
oc get pods -n <namespace>

# Check ClusterServiceVersion
oc get csv -A | grep <package-name>
```

#### Cleanup/Uninstall

To remove an operator installed with `operator-sdk run bundle`:

```bash
# Cleanup the operator
operator-sdk cleanup <package-name>
```

## Troubleshooting

### Image Push Failures

Some registries (Quay.io) decide to give 403 errors when pushing images to newly created repositories.
If this happens, try re-running the `push_containers` task to ensure to retry pushing the images.

## Reference

### Environment Variables Summary

| Variable          | Default              | Description                       |
|-------------------|----------------------|-----------------------------------|
| `NAMESPACE`       | Operator specific    | Operator namespace/directory name |
| `BASE_REGISTRY`   | `quay.io/okderators` | Base container registry URL       |
| `OKD_VERSION`     | `4.20.0-okd-scos.6`  | Target OKD version                |
| `CHANNEL`         | `alpha`              | Operator channel                  |
| `DEFAULT_CHANNEL` | `alpha`              | Default operator channel          |
| `MAJOR`           | Operator specific    | Major version override            |
| `MINOR`           | Operator specific    | Minor version override            |
| `DATE`            | Current timestamp    | Build date override               |

### Build Functions Reference

| Function           | Description                                   | Run by Default |
|--------------------|-----------------------------------------------|----------------|
| `init`             | Initialize git submodules to correct branches | Yes            |
| `deinit`           | Reset and clean git submodules                | Yes            |
| `update`           | Update submodules to latest upstream commits  | **No**         |
| `build_containers` | Build all operator container images           | Yes            |
| `push_containers`  | Push container images to registry             | Yes            |
| `build_bundle`     | Generate, build, and push operator bundle     | Yes            |

## See Also

- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guidelines and build script structure
- [README.md](README.md) - Project overview and operator list
- [operator-sdk documentation](https://sdk.operatorframework.io/docs/)
- [OLM documentation](https://olm.operatorframework.io/)
