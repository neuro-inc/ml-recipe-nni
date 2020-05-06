##### HYPERPARAMETER TRAINING WITH NNI #####
HYPER_TRAIN_MASTER_JOB=train-master-$(PROJECT)
HYPER_TRAIN_WORKER_JOB=train-worker-$(PROJECT)
TRAIN_CMD=USER=root nnictl create --config $(CONFIG_DIR)/nni-config.yml -f

.PHONY: _start_hypertrain-master
_start_hypertrain-master:
	$(NEURO) run $(RUN_EXTRA) \
		--name $(HYPER_TRAIN_MASTER_JOB)-$(RUN) \
		--tag "target:hypertrain" $(_PROJECT_TAGS) \
		--preset cpu-small \
		--detach \
		$(TRAIN_WAIT_START_OPTION) \
		--volume $(PROJECT_PATH_STORAGE)/$(CODE_DIR):$(PROJECT_PATH_ENV)/$(CODE_DIR):ro \
		--volume $(PROJECT_PATH_STORAGE)/$(CONFIG_DIR):$(PROJECT_PATH_ENV)/$(CONFIG_DIR):rw \
		--env PYTHONPATH=$(PROJECT_PATH_ENV) \
		--http 8080 \
		--life-span=0 \
		--pass-config \
		--browse \
		$(OPTION_GCP_CREDENTIALS) $(OPTION_AWS_CREDENTIALS) $(OPTION_WANDB_CREDENTIALS) \
		$(CUSTOM_ENV) \
		bash -c 'cd $(PROJECT_PATH_ENV)/$(CONFIG_DIR) && python3 prepare-nni-config.py && cd $(PROJECT_PATH_ENV) && $(TRAIN_CMD)'

.PHONE: _start-hypertrain-workers
_start-hypertrain-workers:
	@echo "Running $(N_JOBS) worker jobs ..." && \
	for index in `seq 1 $(N_JOBS)` ; do \
	 echo "Starting job $$index..." ; \
	 $(NEURO) run $(RUN_EXTRA) \
	 --name $(HYPER_TRAIN_WORKER_JOB)-$$index-$(RUN) \
	 --tag "target:hypertrain" --tag "hypertrain:worker" $(_PROJECT_TAGS) \
	 --preset $(PRESET) \
	 --detach \
	 $(TRAIN_WAIT_START_OPTION) \
	 --volume $(PROJECT_PATH_STORAGE)/$(CODE_DIR):$(PROJECT_PATH_ENV)/$(CODE_DIR):ro \
	 --volume $(PROJECT_PATH_STORAGE)/$(CONFIG_DIR):$(PROJECT_PATH_ENV)/$(CONFIG_DIR):ro \
	 --env PYTHONPATH=$(PROJECT_PATH_ENV) \
	 --env EXPOSE_SSH=yes \
	 --life-span=0 \
	 $(OPTION_GCP_CREDENTIALS) $(OPTION_AWS_CREDENTIALS) $(OPTION_WANDB_CREDENTIALS) \
	 $(CUSTOM_ENV) \
	 bash -c 'sleep infinity' ; \
	 echo "\n"; \
	done; \
	echo "Started $(N_JOBS) hyperparameter search worker jobs"

.PHONY: kill-hypertrain
kill-hypertrain:  ### Terminate hyper-parameter search training jobs
	jobs=`neuro -q ps --tag "target:hypertrain" $(_PROJECT_TAGS) | tr -d "\r"` && \
	[ ! "$$jobs" ] || $(NEURO) kill $$jobs

.PHONY: hypertrain
hypertrain: _check_setup upload-config upload-code _start-hypertrain-workers _start_hypertrain-master ### Run a hyperparameter tuning training job (set up env var 'RUN' to specify the training job),
	echo Hyper-parameter Tuning started

.PHONY: ps-hypertrain
ps-hypertrain:  ### List running and pending jobs of hyper-parameter search
	$(NEURO) ps --tag "target:hypertrain" $(_PROJECT_TAGS)
