#!/bin/bash

##################################################
# 3/8/2020
# Run deeds non-rigid on accre using accre job array.
##################################################

CONFIG_FILE=$(readlink -f $1)
source ${CONFIG_FILE}
source ${SRC_ROOT}/tools/accre_vlsp_functions.sh

set -o xtrace
mkdir -p ${OUT_MASKED_INPUT_FOLDER}
mkdir -p ${OUT_NON_NAN_FOLDER}
mkdir -p ${OUT_DEEDS_OUTPUT_FOLDER}
mkdir -p ${OUT_WRAPPED_FOLDER}
mkdir -p ${SLURM_LOG_FOLDER}
set +o xtrace

# 1. Generate accre sbatch .sh file
generate_accre_script_job_array

# 2. Run batch
sbatch ${SLURM_BATCH_FILE}