N_JOBS:=3

.PHONY: _start-hypertrain-workers
_start-hypertrain-workers:
	@echo "Running $(N_JOBS) worker jobs ..."
	for index in `seq 1 $(N_JOBS)` ; do \
	 	neuro-flow run nni_worker; \
	done; 
	@echo "Started $(N_JOBS) hyperparameter search worker jobs"

.PHONY: _start_hypertrain-master
_start_hypertrain-master:
	@echo "Running master job"
	neuro-flow run nni_master

.PHONY: hypertrain
hypertrain: _start-hypertrain-workers _start_hypertrain-master
	@echo Hyper-parameter Tuning started