WILDCARD_INGRESS_DNS_FQDN=@@{wildcard_ingress_dns_fqdn}@@
NIPIO_INGRESS_DOMAIN=@@{nipio_ingress_domain}@@
NAMESPACE=@@{namespace}@@
INSTANCE_NAME=@@{instance_name}@@
K8S_CLUSTER_NAME=@@{k8s_cluster_name}@@

# WILDCARD_INGRESS_DNS_FQDN=kalm-main-185.ntnxlab.local
# NIPIO_INGRESS_DOMAIN=10.38.185.43.nip.io
# NAMESPACE=kasten-io
# INSTANCE_NAME=k10
# K8S_CLUSTER_NAME=kalm-main-185

export KUBECONFIG=~/${K8S_CLUSTER_NAME}_${INSTANCE_NAME}.cfg

# Install & Configure Kasten Pre-Check Requirements on Karbon

## 1. Create Default VolumeSnapshotClass and Set as Default

SECRET=$(kubectl get sc -o=jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io\/is-default-class=="true")].parameters.csi\.storage\.k8s\.io\/provisioner-secret-name}')

cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshotClass
metadata:
  name: default-snapshotclass
driver: csi.nutanix.com
parameters:
  storageType: NutanixVolumes
  csi.storage.k8s.io/snapshotter-secret-name: $SECRET
  csi.storage.k8s.io/snapshotter-secret-namespace: kube-system
deletionPolicy: Delete
EOF

## kasten requires this annotation to be set on target snapshot class being leveraged
kubectl annotate volumesnapshotclass default-snapshotclass \
    k10.kasten.io/is-snapshot-class=true

## 2. Add Kasten Helm Repo as it's required for pre-check

helm repo add kasten https://charts.kasten.io/
helm repo update

## 3. Running Pre-Flight Check. This will create k8s job on target K8s cluster and execute various tests

curl https://docs.kasten.io/tools/k10_primer.sh | bash

## 4. Run Helm Install

kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install ${INSTANCE_NAME} kasten/k10 \
	--namespace=${NAMESPACE} \
	--set eula.accept=true \
	--set eula.company=Nutanix \
	--set eula.email=no-reply@nutanix.com \
	--set ingress.host=${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} \
	--set ingress.create=true \
	--set ingress.class=nginx \
	--set ingress.tls.enabled=true \
	--set ingress.tls.secretName=${INSTANCE_NAME}-tls \
	--set-string ingress.annotations."nginx\.ingress\.kubernetes\.io\/ssl-redirect"="true" \
	--set-string ingress.annotations."cert-manager\.io\/cluster-issuer"=selfsigned-cluster-issuer \
	--set auth.tokenAuth.enabled=true \
  --set global.persistence.storageClass=nutanix-volume \
  --set injectKanisterSidecar.enabled=true \
  --set-string injectKanisterSidecar.objectSelector.matchLabels.k10/injectKanisterSidecar=true \
  --set-string injectKanisterSidecar.namespaceSelector.matchLabels.k10/injectKanisterSidecar=true \
  --wait-for-jobs \
	--wait

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=k10 -n ${NAMESPACE}

helm status ${INSTANCE_NAME} -n ${NAMESPACE}

echo "Navigate to https://${INSTANCE_NAME}.${NIPIO_INGRESS_DOMAIN} via browser to access instance

Alternatively, if DNS wildcard domain configured, navigate to https://${INSTANCE_NAME}.${WILDCARD_INGRESS_DNS_FQDN}

After reaching the UI the first time you can login with username: admin and the password will be the
name of the server pod. You can get the pod name by running:

kubectl get secret $(kubectl get serviceaccount -l app=k10 -o jsonpath="{.items[].secrets[].name}" --namespace ${NAMESPACE}) --namespace ${NAMESPACE} -ojsonpath="{.data.token}{'\n'}" | base64 --decode"

echo "Token:"
kubectl get secret $(kubectl get serviceaccount -l app=k10 -o jsonpath="{.items[].secrets[].name}" --namespace ${NAMESPACE}) --namespace ${NAMESPACE} -ojsonpath="{.data.token}{'\n'}" | base64 --decode
