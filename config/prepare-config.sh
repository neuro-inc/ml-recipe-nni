#!/bin/bash

function worker_port() {
  worker_id=$1
  echo 2${worker_id}22
}

function prepare_config_for_worker() {
  worker_id=$1
  worker_port_val=$(worker_port $worker_id)
  echo Creating config entry for worker "${worker_id}" on port "${worker_port_val}"
  sed -e "s/#WORKER_PORT#/${worker_port_val}/" ./worker-config-template.yml >>./config-remote.yml
}

function start_worker() {
  worker_id=$1
  worker_port_val=$(worker_port $worker_id)
  echo Starting worker "${worker_id}"

  neuro run \
    --name train-worker-ml-recipe-nni-${worker_id} \
    --tag "target:hypertrain" --tag "kind:project" --tag "project:ml-recipe-nni" --tag "project-id:neuro-project-992cb0ed" \
    --preset gpu-small \
    --detach \
    --wait-start \
    --volume storage:ml-recipe-nni/modules:/project/modules:ro \
    --volume storage:ml-recipe-nni/config:/project/config:ro \
    --env PYTHONPATH=/project \
    --env EXPOSE_SSH=yes \
    --life-span=0 \
    image:neuromation-ml-recipe-nni:v1.5.1 \
    bash -c 'sleep infinity'

    echo Starting port-forward: "${worker_port_val}":22
    neuro port-forward --no-key-check train-worker-ml-recipe-nni-"${worker_id}" "${worker_port_val}":22 &
}

function main() {
  worker_count=${N_JOBS:-4}

  echo Preparing config for "${worker_count}" workers
  sed -i -e "s/#CONCURRENCY#/${worker_count}/" ./config-remote.yml
  echo "machineList:" >>./config-remote.yml

  for ((worker_id = 1; worker_id <= worker_count; worker_id++)); do
    prepare_config_for_worker $worker_id
  done
  echo "Generated config for ${worker_count} workers"

  for ((worker_id = 1; worker_id <= worker_count; worker_id++)); do
    start_worker $worker_id
  done
}

main
