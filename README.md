# OKD Operator Build Pipeline

**NB** This is a WIP

## Intro

This repository contains the generic tekton pipelines to build operators, which can be used to build any of the 
pre-patched operators defined in the `build.sh` script.

## Don't want to build them yourself?

If you want to get the operators running without the hassle of building them, you can use the pre-built operators 
available in the [OKDerators catalog](https://github.com/okd-project/okderators-catalog-index). 
We try to maintain a similar release cadence to that of OpenShift, however only the latest release of OKD is targeted currently.

## Supported Operators

- Local Storage
- OKD Data Foundation
- GitOps
- Cluster Logging

If an operator is not listed here, please open an issue or check out the [CONTRIBUTING.md](CONTRIBUTING.md) document
to see how you can add it yourself.

## Building

Check out the [BUILDING.md](BUILDING.md) document for instructions on how to build an operator.

## Description

The pipeline relies on the makefile in the specific operator repository.

We are totally aware that not all Makefiles in each operator repository keep the same standards, this means that there will be a fair amount of customization needed to cover all the edge cases.
As mentioned this is a WIP so suggestions, PR's, updates etc are more than welcome

As an example makefile recipes such as :-
- make okd-install
- make okd-lint
- make okd-build
- make okd-test
- make okd-deploy
- make okd-bundle (operator pipeline only)

The pipeline uses 2 tasks (with steps)

- operator
- clone-and-patch
- install (make okd-install)
- lint (make okd-lint)
- build (make okd-build)
- test (make okd-test)
- deploy (make okd-deploy)
- bundle (make okd-bundle)

- operand
- clone-and-patch
- install (make okd-install)
- lint (make okd-lint)
- build (make okd-build)
- test (make okd-test)
- deploy (make okd-deploy)

The reason for the separation into 2 tasks is that the make tasks can be re-used
to build operands (i.e in the node-observability-operator we have an operand (agent) that is required)

A custom golang image is used with the relevant dependencies to execute the various make recipes

The persistent volume and persistent volume claim mounts the golang pkg directory and .cache directories
to speed up builds. 

The pipeline admin will be required to copy the $HOME/.cache/go-build, $HOME/.cache/golangci-lint and $GOPATH/pkg directories to the build-cache pv 

We found that mounting both .cache and pkg directories improved performance dramatically (i.e from 30m to about 6min for the comlpete run)

The verification was done on an on-prem kubernetes 5 node cluster (intel i5's with 16G of ram) and Kind (Kubernetes in Docker). 

We are currently verifying 'microshift' and Code Ready Containers for local development

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

