#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@

LDAP_USER_USER=@@{Ldap User.username}@@
LDAP_USER_PASS=@@{Ldap User.secret}@@

SUBDOMAIN=ntnxlab
ROOTDOMAIN=local

LDAP_DOMAIN=${SUBDOMAIN}.${ROOTDOMAIN}

echo $LDAP_DOMAIN

OCP_BUILD_CACHE_BASE=.local/$OCP_CLUSTER_NAME/.build-cache

mkdir -p $OCP_BUILD_CACHE_BASE

export KUBECONFIG=$HOME/.kube/$OCP_CLUSTER_NAME.cfg

# Create a kubernetes secret for AutoAD administrator password
kubectl create secret generic ldap-secret --from-literal=bindPassword=${LDAP_USER_PASS} -n openshift-config --dry-run=client -o yaml | kubectl apply -f -

# Setup the OAuth provider
cat <<EOF | kubectl apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: ${LDAP_DOMAIN}
    mappingMethod: claim 
    type: LDAP
    ldap:
      attributes:
        id: 
        - sAMAccountName
        email: []
        name: 
        - displayName
        preferredUsername: 
        - sAMAccountName
      bindDN: ${LDAP_USER_USER}
      bindPassword: 
        name: ldap-secret
      insecure: true
      url: "ldap://dc.${LDAP_DOMAIN}/CN=Users,DC=${SUBDOMAIN},DC=${ROOTDOMAIN}?sAMAccountName"
EOF

# Create the LDAP sync config file
cat <<EOF | tee $OCP_BUILD_CACHE_BASE/ldap-sync-config.yaml
kind: LDAPSyncConfig
apiVersion: v1
url: ldap://dc.${LDAP_DOMAIN}:389
insecure: true
bindDN: ${LDAP_USER_USER}
bindPassword: ${LDAP_USER_PASS}
groupUIDNameMapping:
  CN=SSP Admins,CN=Users,DC=${SUBDOMAIN},DC=${ROOTDOMAIN}: ocp-ssp-admins
  CN=SSP Operators,CN=Users,DC=${SUBDOMAIN},DC=${ROOTDOMAIN}: ocp-ssp-operators
  CN=SSP Custom,CN=Users,DC=${SUBDOMAIN},DC=${ROOTDOMAIN}: ocp-ssp-custom
  CN=SSP Consumers,CN=Users,DC=${SUBDOMAIN},DC=${ROOTDOMAIN}: ocp-ssp-consumers
  CN=SSP Developers,CN=Users,DC=${SUBDOMAIN},DC=${ROOTDOMAIN}: ocp-ssp-developers
rfc2307:
  groupsQuery:
    baseDN: cn=users,dc=${SUBDOMAIN},dc=${ROOTDOMAIN}
    filter: (cn=SSP*)
    scope: sub
    derefAliases: never
    pageSize: 0
  groupUIDAttribute: distinguishedName
  groupNameAttributes: [ cn ]
  groupMembershipAttributes:
  - member
  usersQuery:
    baseDN: cn=users,dc=${SUBDOMAIN},dc=${ROOTDOMAIN}
    derefAliases: never
    filter: (objectclass=user)
    scope: sub
    pageSize: 0
  userUIDAttribute: distinguishedName
  userNameAttributes:
  - sAMAccountName
EOF

## synchronize ldap groups 
oc adm groups sync --confirm --sync-config $OCP_BUILD_CACHE_BASE/ldap-sync-config.yaml

## add cluster roles for admins and operators to proper group
oc adm policy add-cluster-role-to-group cluster-admin ocp-ssp-admins
oc adm policy add-cluster-role-to-group cluster-reader ocp-ssp-operators
oc adm policy add-cluster-role-to-group cluster-status ocp-ssp-custom
oc adm policy add-cluster-role-to-group self-provisioner ocp-ssp-consumers
oc adm policy add-cluster-role-to-group edit ocp-ssp-developers

## troubleshooting: 
## https://docs.openshift.com/container-platform/4.12/authentication/using-rbac.html
## oc describe clusterrole.rbac cluster-admin
## oc describe clusterrolebinding.rbac cluster-admin-x
## oc describe group ocp-ssp-admins
## oc describe user adminuser01

## monitor openshift authentication deployment rollout status
kubectl rollout status deploy oauth-openshift -n openshift-authentication
