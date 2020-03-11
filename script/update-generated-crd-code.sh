#!/bin/bash -e

HACK_DIR="$( cd "$( dirname "${0}" )" && pwd -P)"; export HACK_DIR
REPO_ROOT=${HACK_DIR}/..
TRAEFIK_MODULE_VERSION=v2

CRD_SRC_PATH="${REPO_ROOT}"/pkg/provider/kubernetes/crd/traefik/...
CRD_OUTPUT_PATH="${REPO_ROOT}"/docs/content/reference/dynamic-configuration

# Generate the CRD definitions
go run sigs.k8s.io/controller-tools/cmd/controller-gen rbac:roleName=traefik-ingress-controller paths="${CRD_SRC_PATH}" output:dir="${CRD_OUTPUT_PATH}"/rbac crd:crdVersions=v1 paths="${CRD_SRC_PATH}" output:crd:dir="${CRD_OUTPUT_PATH}"/crds

rm -rf "${REPO_ROOT}"/vendor
go mod vendor
chmod +x "${REPO_ROOT}"/vendor/k8s.io/code-generator/*.sh

"${REPO_ROOT}"/vendor/k8s.io/code-generator/generate-groups.sh \
  all \
  github.com/containous/traefik/${TRAEFIK_MODULE_VERSION}/pkg/provider/kubernetes/crd/generated \
  github.com/containous/traefik/${TRAEFIK_MODULE_VERSION}/pkg/provider/kubernetes/crd \
  traefik:v1alpha1 \
  --go-header-file "${HACK_DIR}"/boilerplate.go.tmpl \
  "$@"

deepcopy-gen \
--input-dirs github.com/containous/traefik/${TRAEFIK_MODULE_VERSION}/pkg/config/dynamic \
--input-dirs github.com/containous/traefik/${TRAEFIK_MODULE_VERSION}/pkg/tls \
--input-dirs github.com/containous/traefik/${TRAEFIK_MODULE_VERSION}/pkg/types \
--output-package github.com/containous/traefik \
-O zz_generated.deepcopy --go-header-file "${HACK_DIR}"/boilerplate.go.tmpl

cp -r "${REPO_ROOT}"/"${TRAEFIK_MODULE_VERSION:?}"/* "${REPO_ROOT}"; rm -rf "${REPO_ROOT}"/"${TRAEFIK_MODULE_VERSION:?}"

rm -rf "${REPO_ROOT}"/vendor
