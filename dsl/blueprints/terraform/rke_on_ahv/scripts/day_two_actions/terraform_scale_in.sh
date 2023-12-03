# change working directory
cd rke-on-ahv/terraform

SCALE_COUNT=@@{ScaleIn}@@

CURRENT_WORKER_COUNT=$(kubectl get nodes -o name -l node-role.kubernetes.io/worker=true | wc -l)

TARGET_WORKER_COUNT=$(expr $CURRENT_WORKER_COUNT - $SCALE_COUNT)

echo $TARGET_WORKER_COUNT

terraform plan -var amount_of_rke_worker_vms=$TARGET_WORKER_COUNT

terraform apply -var amount_of_rke_worker_vms=$TARGET_WORKER_COUNT -auto-approve
