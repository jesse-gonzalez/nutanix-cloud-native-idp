#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BASE_DOMAIN=@@{ocp_base_domain}@@

DNS_DOMAIN=@@{domain_name}@@
DNS_SERVER_IP=@@{dns_server}@@

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

cat <<EOF | kubectl apply -f -
apiVersion: operator.openshift.io/v1
kind: DNS
metadata:
  name: default
spec:  
  logLevel: Normal
  nodePlacement: {}
  operatorLogLevel: Normal
  servers:
    - forwardPlugin:
        policy: Random
        upstreams:
          - $DNS_SERVER_IP
      name: ntnxlabs-local
      zones:
        - $DNS_DOMAIN
  upstreamResolvers:
    policy: Sequential
    transportConfig: {}
    upstreams:
      - port: 53
        type: SystemResolvConf
EOF

oc describe clusteroperators/dns
oc describe dns.operator/default
oc get configmap/dns-default -n openshift-dns -o yaml

#DST_HOST=ntnx-objects.ntnxlab.local; for dnspod in `oc get pods -n openshift-dns -o name --no-headers -l dns.operator.openshift.io/daemonset-dns=default`; do for dnsip in `oc get pods -n openshift-dns -o go-template='{{ range .items }} {{index .status.podIP }} {{end}}' -l dns.operator.openshift.io/daemonset-dns=default`; do echo -ne "$dnspod\tquerying $DST_HOST to $dnsip ->\t"; oc exec -n openshift-dns $dnspod -- dig @$dnsip $DST_HOST -p 5353 +short 2>/dev/null ; done; done