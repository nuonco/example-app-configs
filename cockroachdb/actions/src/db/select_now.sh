#!/bin/bash

set -e
set -o pipefail
set -u

# get pod name from cockroachdb-client-secure
pod=$(kubectl get pods -n cockroach --field-selector=metadata.name=cockroachdb-client-secure -o jsonpath='{.items[0].metadata.name}')

# exec in pod
kubectl exec -n cockroach "$pod" -- cockroach sql \
  --certs-dir=/cockroach/cockroach-certs \
  --host=cockroachdb-public.cockroach.svc.cluster.local \
  -e "SELECT now();"
