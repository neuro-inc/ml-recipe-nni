#!/bin/bash

echo Starting worker ${WORKER_ID}

neuro run  \
		--name train-master-ml-recipe-nni-worker-${WORKER_ID} \
		--tag "target:hyper-train" --tag "kind:project" --tag "project:ml-recipe-nni" --tag "project-id:neuro-project-992cb0ed" \
		--preset cpu-small \
		--detach \
		--wait-start --detach \
		--volume storage:ml-recipe-nni/modules:/project/modules:ro \
		--volume storage:ml-recipe-nni/config:/project/config:ro \
		--env PYTHONPATH=/project \
		--env EXPOSE_SSH=yes \
		--life-span=0 \
		image:neuromation-ml-recipe-nni:v1.5.1 \
		bash -c 'sleep 2h'

neuro port-forward --no-key-check train-master-ml-recipe-nni-worker-${WORKER_ID} 2${WORKER_ID}22:22 &
