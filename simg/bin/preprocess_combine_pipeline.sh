#!/bin/bash

##################################################
# 3/26/2020 - Kaiwen
# For singularity situation.
# Generate the configuration files and the run script
##################################################

CONFIG_FILE=/src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh
source ${CONFIG_FILE}
source ${NON_RIGID_SRC_ROOT}/tools/functions_affine_deformable_singularity.sh

OUT_DATA_FOLDER=${PROJ_ROOT}/output
mkdir -p ${OUT_DATA_FOLDER}

# 1. Generate configuration file for affine
AFFINE_ROOT=${OUT_DATA_FOLDER}/affine
mkdir -p ${AFFINE_ROOT}
AFFINE_CONFIG=${AFFINE_ROOT}/config.sh
generate_affine_bash_config \
  ${AFFINE_CONFIG} \
  ${IN_DATA_FOLDER} \
  ${AFFINE_ROOT} \
  ${AFFINE_REFERENCE}
${AFFINE_SRC_ROOT}/run_reg_block_prepare.sh ${AFFINE_CONFIG}

# 2. Generate configuration file for non-rigid
NON_RIGID_ROOT=${OUT_DATA_FOLDER}/non_rigid
mkdir -p ${NON_RIGID_ROOT}
NON_RIGID_INPUT_FOLDER=${AFFINE_ROOT}/interp/ori
NON_RIGID_CONFIG=${NON_RIGID_ROOT}/config.sh
generate_non_rigid_bash_config \
  ${NON_RIGID_CONFIG} \
  ${NON_RIGID_INPUT_FOLDER} \
  ${NON_RIGID_ROOT} \
  ${REFERENCE_FOLDER} \
  ${AFFINE_ROOT}/interp

# 3. Generate run script for single scan
generate_non_slurm_job_script \
  ${RUN_SCRIPT_PATH} \
  ${AFFINE_CONFIG} \
  ${NON_RIGID_CONFIG}
