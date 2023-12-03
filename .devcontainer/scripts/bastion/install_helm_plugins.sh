#!/bin/bash
set -e
set -o pipefail

## install helm plugins - secrets

helm plugin install https://github.com/futuresimple/helm-secrets && \
helm secrets -h

## install helm plugins - diff
helm plugin install https://github.com/databus23/helm-diff && \
helm diff -h
