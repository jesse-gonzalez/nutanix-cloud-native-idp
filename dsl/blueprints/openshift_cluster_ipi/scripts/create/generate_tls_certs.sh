#!/bin/bash
set -e
set -o pipefail

OCP_CLUSTER_NAME=@@{ocp_cluster_name}@@
OCP_BASE_DOMAIN=@@{ocp_base_domain}@@

export AWS_ACCESS_KEY_ID=@@{AWS Access Key.username}@@
export AWS_SECRET_ACCESS_KEY=@@{AWS Access Key.secret}@@
export DOMAIN_ADMIN_EMAIL=admin@no-reply.com

export CERTDIR=.local/$OCP_CLUSTER_NAME/certs

[ -d $CERTDIR ] || mkdir -p  $CERTDIR

## register admin email account for domain
$HOME/.acme.sh/acme.sh --register-account -m $DOMAIN_ADMIN_EMAIL

## generate DNS_01 validated certs
$HOME/.acme.sh/acme.sh --issue \
  --dns dns_aws -d "*.$OCP_CLUSTER_NAME.$OCP_BASE_DOMAIN" \
  --dns dns_aws -d "api.$OCP_CLUSTER_NAME.$OCP_BASE_DOMAIN" \
  --dns dns_aws -d "*.apps.$OCP_CLUSTER_NAME.$OCP_BASE_DOMAIN" \
  --cert-file $CERTDIR/cert.pem \
  --key-file $CERTDIR/key.pem \
  --fullchain-file $CERTDIR/fullchain.pem \
  --ca-file $CERTDIR/ca.cer \
  --standalone \
  --force
