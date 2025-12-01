#!/usr/bin/env bash

# This script is concerned with running the temporal sql tools to migrate the db etc.

set -e
set -o pipefail
set -u

region="$REGION"

echo "[temporal init] kubectl auth whoami"
echo "pwd: "`pwd`
kubectl auth whoami -o json | jq -c

echo "[temporal init] scale up the deployment"
kubectl scale -n temporal --replicas=1 deployment/temporal-psql
kubectl wait deployment -n temporal temporal-psql --for condition=Available=True --timeout=300s

echo "[temporal init] get a pod from the deployment"
pod=`kubectl -n temporal get pods --selector app=temporal-psql -o json | jq -r '.items[0].metadata.name'`

# TOOD(fd): make the username and database an input or const (or at least document it heavily)
echo "[temporal init] ensure db users"
  kubectl \
    --namespace=temporal \
    exec  -i \
    $pod --  \
    sh -c 'bash /var/init-config/create_db_users.sh temporal temporal $TEMPORAL_DB_PW'

echo "[temporal init] ensure db users"
  kubectl \
    --namespace=temporal \
    exec  -i \
    $pod --  \
    sh -c 'bash /var/init-config/create_db_users.sh temporal_visibility temporal_visibility $TEMPORAL_VISIBILITY_DB_PW'

# this scripts run a sql script which should be idempotent
echo "[temporal init] describe users"
kubectl \
  --namespace=temporal \
  exec  -i \
  $pod -- \
  psql --no-psqlrc -d "temporaladmin" -c "\\du"


echo "[temporal init] scale down the deployment"
kubectl scale -n temporal --current-replicas=1 --replicas=0 deployment/temporal-psql
