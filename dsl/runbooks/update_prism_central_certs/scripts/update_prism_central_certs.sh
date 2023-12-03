#!/bin/bash
set -e
set -o pipefail

NTNX_PC_IP=@@{pc_instance_ip}@@
NTNX_PC_PASS="@@{Nutanix Password.secret}@@"
OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BASE_DOMAIN=@@{ocp_base_domain}@@

CERTDIR=.local/_certs/$OCP_BASE_DOMAIN/$OCP_CLUSTER_NAME

## copy certs to prism central and import / replace certs
sshpass -p $NTNX_PC_PASS scp $CERTDIR/*.{cer,pem} nutanix@$NTNX_PC_IP:/tmp
sshpass -p $NTNX_PC_PASS ssh nutanix@$NTNX_PC_IP -C "export PATH=$PATH:/home/nutanix/prism/cli:/usr/local/nutanix/bin ; ncli ssl-certificate import key-type=RSA_2048 key-path=/tmp/key.pem certificate-path=/tmp/cert.pem cacertificate-path=/tmp/ca.cer"
