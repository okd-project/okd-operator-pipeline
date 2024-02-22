# Tekton Operator Build Pipeline

## Intro

All the necessary yaml files to deploy a generic tekton pipeline to build operators

**NB** This is a WIP 

## Description

The pipeline relies on the makefile in the specific operator repository.

We are totally aware that not all Makefiles in each operator repository keep the same standards, this means that there will be a fair amount of customization needed to cover all the edge cases.
As mentioned this is a WIP so suggestions, PR's, updates etc are more than welcome

As an example makefile recipes such as :-
- make okd-install
- make okd-lint
- make okd-build
- make okd-test
- make okd-bundle

The pipeline uses 2 tasks (with steps)

- operator
  - clone-and-patch
  - get-id (appends timestamp to version)
  - install (make okd-install)
  - lint (make okd-lint)
  - build (make okd-build)
  - test (make okd-test)
  - build-operator (buildah-build)
  - push-operator (buildah-push)
  - make-bundle (make okd-bundle)
  - build-bundle (buildah-build)
  - push-bundle (buildah-push)

- operand
  - clone-and-patch
  - install
  - lint

The reason for the separation into 2 tasks is that the make/buildah tasks can be re-used
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

### Install Tekton Polling Operator

The Tekton polling operator is used to trigger the pipeline when a new commit is pushed to the origin repository. 

see (https://github.com/bigkevmcd/tekton-polling-operator/blob/main/README.md#installation)

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
kubectl apply -k environments/overlays/cicd

# check that all resources have deployed
kubectl get all -n okd-team
kubectl get pvc -n okd-team

# once all pods are in the RUNNING status create a configmap as follows
# this assumes you have the correct credentials and have logged into the registry to push images to
kubectl create configmap docker-config --from-file=/$HOME/.docker/config.json -n okd-team
```

## Usage

### Option 1 - On clusters with existing PVCs

Execute the following to start a pipeline run, this will re-use the claim "pipeline-pvc-dev" for
future builds, it will re-use the .cache and pkg dirs to speed up builds

```bash
# example (using the node-observability-operator)
tkn pipeline start pipeline-dev-all \
--param repo-url=https://github.com/openshift/node-observability-operator \
--param repo-name=node-observability-operator \
--param base-image-registry=quay.io/<your-repo-id> \
--param bundle-version=0.0.1 \
--param channel=preview \
--param default-channel=preview \
--param catalog-image=quay.io/okd/okd-dev-community-operator=0.0.1 \
--workspace name=shared-workspace,claimName=pipeline-pvc-dev \
-n okd-team
```

### Option 2 - No existing PVCs

```bash
# example (using the node-observability-operator)
tkn pipeline start pipeline-dev-all \
--param repo-url=https://github.com/openshift/node-observability-operator \
--param repo-name=node-observability-operator \
--param base-image-registry=quay.io/<your-repo-id> \
--param bundle-version=0.0.1 \
--param channel=preview \
--param default-channel=preview \
--param catalog-image=quay.io/okd/okd-dev-community-operator=0.0.1 \
--workspace name=shared-workspace,volumeClaimTemplateFile=manifests/tekton/pipelineruns/workspace-template.yaml \
-n okd-team
```


## Dockerfile

**NB - you can skip this step**

There is an image that has been pushed to the quay.io registry with the latest version of all dependencies

```
quay.io/okd/go-bundle-tools:v1.1.0
```

This image is referrenced in all the tasks. **NB** change these references when you create your own image.

The dockerfile includes the base ubi image with all the relevant tools to compile and build the bundles. 
The versions of most components have been updated to use the latest (please update and re-create as needed)

To build the image simply execute

```bash
# change the tag i.e (v1.1.0) for different versioning
podman build -t quay.io/<id>/go-bundle-tools:v1.1.0 .
podman push push quay.io/<id>/go-bundle-tools:v1.1.0

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

## Troubleshooting 

This is specifc for **kind** local dev clusters

Create a config file for the kind cluster

```bash
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4 
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /data
    containerPath: /var/local-path-provisioner 
```

Ensure the hostPath directory is created

```bash
mkdir /data
```

We have created some utility yaml files in the directory *manifests/tekton/utility/base*

The pvc-local.yaml will create a local path persistent volume (to be used for local testing). This is a manual setup for local debugging, it will allow the user to copy and change
setting as needed.

If needed use the debug-pod.yaml to deploy a *ubi-init* container to debug the mounted pv.

Create the pvc 

```bash

kubectl apply -f manifests/tekton/utility/base/pvc-local.yaml

# copy your local go-build cache to the pv directory (as set in the config.yaml file for the Kind cluster)
# note the privisioner will create a random path in the form of 'pvc-xxx_namespace_pvcname'
cp -r $HOME/.cache/go-build /data/pvc-xxx_okd-team_local-volume-pvc/.cache/
# copy the golangci-lint cache to the pv directory
cp -r $HOME/.cache/golangci-lint /data/pvc-xxx_okd-team_local-volume-pvc/.cache/

```

Use the following command line to re-use the PVC and PV for all future pipelineruns

```bash
tkn pipeline start pipeline-dev-all \
--param repo-url=<url-to-github-repo> \
--param repo-name=<repo-name> \
--param base-image-registry=quay.io/<your-repo-id> \
--param bundle-version=<bundle-version> \
--workspace name=shared-workspace,claimName=local-volume-pvc \
-n okd-team
```


To create a re-usable PVC use the following (this example is for operate-first)

```bash
# find the storage class on your cluster before executing this command
# for operate-first the storage class is ocs-external-storagecluster-ceph-rbd 
sed -e 's|${STORAGE_CLASS}|ocs-external-storagecluster-ceph-rbd|g' manifests/tekton/utility/base/pvc.yaml | kubectl apply -f - 

# create the debug pod so that you can rsync the local go-build and golangci-lint caches to the PVC
sed -e 's|${PVC_NAME}|manual-pvc|g' manifests/tekton/utility/base/debug-pod.yaml | kubectl apply -f -

# once the pod has been created execute the following command
# this will push the golang-build and golangci-lint cache to the PVC just created in the previous step
oc rsync /<local-dirctory-for-go-build-and-golangci-lint-cache>/ debugs-pod:/tmp

# verify that the cache on the PVC on the debug-pod
oc exec -it debug-pod -- bash
$ ls -la /tmp
$ drwxrwxrwx. 1      101000      101000 1052 Oct 14 14:36 go-build
$ drwxrwxrwx. 1      101000      101000 1052 Oct 14 14:36 golangci-lint 

# delete the pod once completed
oc delete pod debug-pod

# use the following command line to start the pipeline 
# the default name for the PVC is called 'manual-pvc' (feel free to change it)
tkn pipeline start pipeline-dev-all \
--param repo-url=<url-to-github-repo> \
--param repo-name=<repo-name> \
--param base-image-registry=quay.io/<your-repo-id> \
--param bundle-version=<bundle-version> \
--workspace name=shared-workspace,claimName=manual-pvc \
-n okd-team
```
**Mounting the go-build and golangci-lint cache files**

- If you are experiencing problems with mounting the cache directories
in the container to speed up linting and building, try doing the following (this is specifically for SELinux enabled OS's)

```bash
# check chcon settings
ls -LZ <pv-directory-for-cache>/.cache/go-build
# it should have the following settings 
# system_u:object_r:container_file_t:s0
# update if not
sudo chcon -R system_u:object_r:container_file_t:s0 <pv-directory-for-cache>/.cache/go-build
# repeat for golangci-lint

```
- In fact if you have any problems with mounting any other directory check the SELinux
settings and apply the *system_u:object_r:container_file_t:s0* via chcon

