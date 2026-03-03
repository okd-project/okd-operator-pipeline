# OKD Operator Builds

Build scripts for packaging OpenShift operators for OKD.

## Overview

This repository contains build scripts and configuration for rebuilding OpenShift operators to work with OKD. It uses git submodules to track upstream operator repositories and provides automated build tooling to create OKD-compatible operator images and bundles.

## Supported Operators

The pipeline supports building the following operators:
- **data-foundation**: OKD Data Foundation (Ceph, Rook, NooBaa, ODF)
- **local-storage**: Local Storage Operator
- **lvms**: Logical Volume Manager Storage
- **oadp**: OKD API for Data Protection (Velero)
- **metallb**: MetalLB load balancer
- **nmstate**: Network Manager State
- **sr-iov**: SR-IOV Network Operator
- **ingress-node-firewall**: Ingress Node Firewall Operator
- **network-observability**: Network Observability Operator
- **acm**: Advanced Cluster Management (Submariner, governance, observability)
- **multicluster-engine**: Multicluster Engine (Hive, Hypershift, assisted installer)
- **service-mesh**: OpenShift Service Mesh (Istio, Kiali)
- **cluster-logging**: Cluster Logging (Loki, Vector)
- **cluster-observability**: Cluster Observability Operator
- **cert-manager**: Cert Manager Operator
- **external-secrets**: External Secrets Operator
- **node-feature-discovery**: Node Feature Discovery
- **gitops**: GitOps (ArgoCD)
- **web-terminal**: Web Terminal Operator

## Building Operators
Check out [BUILDING.md](BUILDING.md) for detailed instructions on how to build an operator.

## Git Submodules

This repository uses git submodules extensively to track upstream operator sources. Submodules are automatically managed by the build scripts.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

This repository is licensed under the Apache License, Version 2.0. Individual operators maintain their own licenses - see each submodule for details.
