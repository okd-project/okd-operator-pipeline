# Building an operator (WIP)

This document describes how to build an operator already defined in the `build.sh` script. If you want to build a 
new operator, you need to follow the steps described in the [CONTRIBUTING.md](CONTRIBUTING.md) document.

## Prerequisites

- Kubernetes cluster (preferably OKD/CRC)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) or [oc](https://github.com/okd-project/okd/releases) installed - for interacting with the Kubernetes cluster
- [Tekton Pipelines](https://tekton.dev/docs/pipelines/install/) installed - for building the operator
- [Tekton CLI](https://tekton.dev/docs/cli/) installed - for running the operator pipelines
- [Tekton Polling Operator](https://github.com/bigkevmcd/tekton-polling-operator) installed - for the Repository CRDs
- PVC provisioner installed - for creating the PVCs used by the operator
- Access to a Docker registry - for pushing the operator and operand images

# Installing

### Clone the repository

```bash
git clone git@github.com:okd-project/okd-operator-pipeline.git

```

### Install the storage provisioner (All clusters)

This example uses an NFS provisioner for an on-prem kubernetes cluster

Skip this step (go to [Install the operator tekton pipeline with kustomize](###install-the-operator-tekton-pipeline-with-kustomize)) if you already have storage (storageClass and provisioner) setup, as it is the case on Kind clusters for example, with the `standard` storageClass.

**NB** Before executing the provisioner, change the fields that relate to your specific
NFS setup i.e server name (ip) and path in the file environments/overlays/nfs-provisioner/patch_nfs_details.yaml

```bash
# execute for kustomize
cd okd-operator-pipeline
kubectl apply -k environments/overlays/nfs-provisioner
```

### Install the operator tekton pipeline with kustomize

Execute the following commands

```bash
cd okd-operator-pipeline
# create the okd-team namespace (if not already created)
kubectl create ns okd-team

# assume you are logged into your kubernetes cluster
# use `environments/overlays/kind` for a kind cluster
# use  `environments/overlays/operate-first` on OperateFirst cluster
kubectl apply -k base/tasks
kubectl apply -k base/pipelines
kubectl apply -k base/repositories/<operator> # where <operator> is the operator you want to build

# check that all resources have deployed
kubectl get all -n okd-team
kubectl get pvc -n okd-team

# once all pods are in the RUNNING status create a configmap as follows
# this assumes you have the correct credentials and have logged into the registry to push images to
kubectl create configmap docker-config --from-file=/$HOME/.docker/config.json -n okd-team

# Now you can build an operator. The command will follow the logs of the build.
BASE_IMAGE_REGISTRY=quay.io/changeme build.sh <operator>
```

## Container Images

**NB - you can skip this step**

There is an image that has been pushed to the quay.io registry with the latest version of all dependencies

```
quay.io/okderators/go-bundle-tools:v1.1.0
```

This image is referenced in all the tasks. **NB** change these references when you create your own image.

The dockerfile includes the base ubi image with all the relevant tools to compile and build the bundles.
The versions of most components have been updated to use the latest (please update and re-create as needed)

To build the image simply execute

```bash
# change the tag i.e (v1.1.0) for different versioning
podman build -t quay.io/<id>/go-bundle-tools:v1.1.0 .
podman push push quay.io/<id>/go-bundle-tools:v1.1.0

# remember to update the tasks in manifests/tekton/tasks/base to reflect the changed image
```
