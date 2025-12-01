#!/usr/bin/env bash

"""
This script is concerned with running the temporal sql tools to migrate the db etc.
"""

set -e
set -o pipefail
set -u

region="$REGION"

echo "[temporal init] kubectl auth whoami"
echo "pwd: "`pwd`
kubectl auth whoami -o json | jq -c

echo "[temporal init] scale up the deployment"
kubectl scale -n temporal --replicas=1 deployment/temporal-init
kubectl wait deployment -n temporal temporal-init --for condition=Available=True --timeout=300s

echo "[temporal init] get a pod from the deployment"
pod=`kubectl -n temporal get pods --selector app=temporal-init -o json | jq -r '.items[0].metadata.name'`

echo "[temporal init] preparing to initialize"
function run_cmd() {
  echo " > cmd: $@"
  kubectl \
    --namespace=temporal \
    exec  -i \
    $pod --  \
    sh -c "$1"
}

# TODO(fd): update to a version of admintools that has idempotent commands
#
# these scripts run bash scripts which should be allowed to fail
echo "[temporal init] sql tools - temporal db"
run_cmd "bash /var/init-config/init_temporal_db.sh"

echo "[temporal init] sql tools - temporal_visibilty db"
run_cmd "bash /var/init-config/init_visibility_db.sh"

echo "[temporal init] scale down the deployment"
kubectl scale -n temporal --current-replicas=1 --replicas=0 deployment/temporal-init
