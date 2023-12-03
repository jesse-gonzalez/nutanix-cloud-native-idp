WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

echo "Initialize Docker and Helm Chart Local Repository"

echo 'localRepositories:
  docker-dev-local:
    type: docker
    checksumPolicyType: server-generated-checksums
    description: "local docker dev repo"
    dockerApiVersion: V2
    excludesPattern:
    includesPattern:
    maxUniqueSnapshots: 0
    maxUniqueTags: 0
    repoLayout: simple-default
    snapshotVersionBehavior: unique
    xray:
      enabled: false
    blackedOut: false
    enableFileListsIndexing: false
    forceNugetAuthentication: false
    handleReleases: true
    handleSnapshots: true
    suppressPomConsistencyChecks: true
  helm-dev-local:
    type: helm
    checksumPolicyType: server-generated-checksums
    description: "local helm dev repo"
    dockerApiVersion: V2
    excludesPattern:
    includesPattern:
    maxUniqueSnapshots: 0
    maxUniqueTags: 0
    repoLayout: simple-default
    snapshotVersionBehavior: unique
    xray:
      enabled: false
    blackedOut: false
    enableFileListsIndexing: false
    forceNugetAuthentication: false
    handleReleases: true
    handleSnapshots: true
    suppressPomConsistencyChecks: true' > ~/artifactory-repo-config.yml

#configure local artifactory repos
curl -kv -u admin:password -X PATCH "https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/artifactory/api/system/configuration" -H “Content-Type:application/yaml” -T ~/artifactory-repo-config.yml

#configure virtual artifactory repos
echo 'virtualRepositories:
  docker:
    type: docker
    repositories:
      - docker-dev-local
    defaultDeploymentRepo: docker-dev-local
    dockerApiVersion: V2
    repoLayout: simple-default
  helm:
    type: helm
    repositories:
      - helm-dev-local
    defaultDeploymentRepo: helm-dev-local
    dockerApiVersion: V2
    repoLayout: simple-default' > ~/artifactory-virtual-repo-config.yml

#configure virtual artifactory repos
curl -kv -u admin:password -X PATCH "https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/artifactory/api/system/configuration" -H “Content-Type:application/yaml” -T ~/artifactory-virtual-repo-config.yml

#accept eula
curl -kv -u admin:password -X POST "https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/artifactory/ui/jcr/eula/accept"

#change password
curl -kv -u admin:password -X POST "https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN}/artifactory/api/security/users/authorization/changePassword" -H "Content-type: application/json" -d '{ "userName" : "admin", "oldPassword" : "password", "newPassword1" : "@@{Artifactory Credential.secret}@@", "newPassword2" : "@@{Artifactory Credential.secret}@@" }'
