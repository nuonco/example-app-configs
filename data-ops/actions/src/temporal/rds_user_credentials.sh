#!/usr/bin/env sh

set -e
set -o pipefail
set -u

temporal_db_pw=`kubectl get -n temporal secret temporal-temporal-db-pw -o json | jq -r '.data.value' | base64 -d`
kubectl create -n temporal secret generic temporal-db-pw \
  --save-config    \
  --dry-run=client \
  --from-literal=password="$temporal_db_pw" \
  -o yaml | kubectl apply -f -

visibility_db_pw=`kubectl get -n temporal secret temporal-visibility-db-pw -o json | jq -r '.data.value' | base64 -d`
kubectl create -n temporal secret generic visibility-db-pw \
  --save-config    \
  --dry-run=client \
  --from-literal=password="$visibility_db_pw" \
  -o yaml | kubectl apply -f -
