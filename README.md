# Tekton Operator Build Pipeline

## Intro

All the necessary yaml files to deploy a generic tekton pipeline to build operators

**NB** This is a WIP 

## Description

The pipeline relies on the makefile in the specific operator repository.

We are totally aware that not all Makefiles in each operator repository keep the same standards, this means that there will be a fair amount of customization needed to cover all the edge cases.
As mentioned this is a WIP so suggestions, PR's, updates etc are more than welcome

As an example makefile recipes such as :-
- make verify
- make test
- make build
- make container-build

The pipeline uses 2 tasks (with steps)

- container-all
  - git-clone
  - verify (golangci-lint)
  - test (unit tests)
  - build (go compile to binary)
  - build and push image

- bundle-all
  - bundle 
  - bundle-image-push
  - index-image-build
  - index-image-push
  - catalog-image-build
  - catalog-image-push 

The reason for the separation into 2 tasks is that the *container-all* task can be re-used
to build operands (i.e in the node-observability-operator we have an operand (agent) that is required)

A custom golang image is used with the relevant dependencies to execute the various make recipes

The persistent volume and peristent volume claim mounts the golang pkg directory and .cache directories
to speed up builds. 

The pipeline admin will be required to copy the $HOME/.cache/go-build, $HOME/.cache/golangci-lint and $GOPATH/pkg directories to the build-cache pv 

We found that mounting both .cache and pkg directories improved performance dramatically (i.e from 30m to about 6min for the comlpete run)

The verification was done on an on-prem kubernetes 5 node cluster (intel i5's with 16G of ram) and Kind (Kubernetes in Docker). 

We are currently verifying 'microshift' and Code Ready Containers for local development

## Installation

During the installation, some of the steps are specific to a regular Kubernetes cluster, while others are specific to Kind clusters. 

### Install Tekton Operator

Install the tekton cli and tekton resources before continuing (see https://tekton.dev/docs/pipelines/install)

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
cd pipelines
kubectl apply -k environments/overlays/nfs-provisioner
```

### Install the operator tekton pipeline with kustomize

__Note__: For Kind clusters, or when using VolumeClaimTemplate, start by commenting the following lines from the `resources` list in `environments/overlays/cicd/kustomization.yaml`:
```yaml
resources:
  - namespace/namespace.yaml
#  - pvc/pipeline-pvc.yaml
#  - pvc/build-cache-pvc.yaml
```

Execute the following commands

```bash
# assume you logged into your kubernetes cluster
kubectl apply -k environments/overlays/cicd

# check that all resources have deployed
kubectl get all -n operator-pipeline
# If not running on Kind, also check PVCs are available
kubectl get pvc -n operator-pipeline

# once all pods are in the RUNNING status create a configmap as follows
# this assumes you have the correct credentials and have logged into the registry to push images to
kubectl create configmap docker-config --from-file=/$HOME/.docker/config.json -n operator-pipeline
```

## Usage

### Option 1 - On clusters with existing PVCs

Execute the following to start a pipeline run, this will re-use the claim "pipeline-pvc-dev" for
future builds, it will re-use the .cache and pkd dirs to speed up builds

```bash
# example (using the node-observability-operator)
tkn pipeline start pipeline-dev-all \
--param repo-url=https://github.com/openshift/node-observability-operator \
--param repo-name=node-observability-operator \
--param base-image-registry=quay.io/<your-repo-id> \
--param bundle-version=v0.0.1 \
--workspace name=shared-workspace,claimName=pipeline-pvc-dev \
-n okd-team
```

### Option 2 - Kind clusters, or without existing PVCs

```bash
# example (using the node-observability-operator)
tkn pipeline start pipeline-dev-all \
--param repo-url=https://github.com/openshift/node-observability-operator \
--param repo-name=node-observability-operator \
--param base-image-registry=quay.io/<your-repo-id> \
--param bundle-version=v0.0.1 \
--workspace name=shared-workspace,volumeClaimTemplateFile=manifests/tekton/pipelineruns/workspace-template.yaml \
-n okd-team
```


## Dockerfile

The dockerfile includes the base ubi image with all the relevant tools to compile and build the bundles. 
The versions of most components have been updated to use the latest (please update and re-create as needed)

To build the image simply execute

```bash
# change the tag i.e (v1.0.0) for different versioning
podman build -t quay.io/<id>/go-bundle-tools:v1.0.0 .
podman push push quay.io/<id>/go-bundle-tools:v1.0.0

# remember to update the tasks in manifests/tekton/tasks/base to reflect the changed image
```

## Next Steps

We are currently implementing a simple golang webhook so that the pipeline can be triggered remotely.
It will interface with the tekton eventListener (see manifests/tekton/triggers/base).

A typical call could look like this

```bash

curl -d'{"repourl":"https://github.com/<id>/<repo>","bundleversion":"v0.0.1","imageregistry":"quay.io/<id>"}' https://trigger-webhook.tekton-cilab.com
```

The trigger-webhook will then format and post the required "bindings" to the tekton eventListener


## Pipelinefolder structure

The folder structure is as follows :

```bash

      --- environments
      |     |
      |     --- overlays
      |           |
      |           --- cicd
      |           |     |
      |           |     --- pvc
      |           |     |     |
      |           |     |     --- pipeline-pvc.yaml
      |           |     |     --- build-cache-pvc.yaml
      |           |     |
      |           |     --- kustermization.yaml
      |           |
      |           --- nfs-provisioner
      |                 |
      |                 --- kustomization.yaml
      |                 --- namespace.yaml
      |                 --- patch_nfs_details.yaml
      |
      --- manifests
            |
            --- tekton
                  |
                  --- tasks
                  |     |
                  |     --- base
                  |           |
                  |           --- container-all.yaml
                  |           --- bundle-all.yaml
                  |
                  --- rbac
                  |     |
                  |     --- base
                  |           |    
                  |           --- admin.yaml
                  |           --- edit.yaml
                  |           --- view.yaml
                  |           --- kustermization.yaml
                  --- pipelines
                        |
                        --- base
                              |    
                              --- pipeline-dev.yaml
                              --- pipeline-dev-all.yaml
                              --- kustomization.yaml
                  --- pipelineruns
                        |
                        --- sample-pr-dev-all-on-kind.yaml
                        --- workspace-template.yaml
```
