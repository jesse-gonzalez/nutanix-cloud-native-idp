#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache

## generate the install manifests
openshift-install create manifests --dir $OCP_BUILD_CACHE_BASE

ls -al $OCP_BUILD_CACHE_BASE/manifests $OCP_BUILD_CACHE_BASE/openshift

## backup manifest dir in case it's needed for debugging
cp -rf $OCP_BUILD_CACHE_BASE "${OCP_BUILD_CACHE_BASE}_backup"

## generate ignition files
openshift-install create ignition-configs --dir $OCP_BUILD_CACHE_BASE
