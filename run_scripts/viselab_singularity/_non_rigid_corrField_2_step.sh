#!/bin/bash

# Call this script using non_rigid_entry_point.sh
# example file. Put this into the project root folder and run.

#  Example for config.sh --
#  data_root=/data_root
#  TEST_DATA_FOLDER=${data_root}/corrField_root/data_shared
#  MOVING_FOLDER=${data_root}/output/affine/interp/ori
#  MASK_FOLDER=${data_root}/output/affine/interp
#  FILE_LIST=${data_root}/data/file_list
#  FIXED_IMG=${TEST_DATA_FOLDER}/fixed.nii.gz
#  MASK_IMG=${TEST_DATA_FOLDER}/mask_body.nii.gz
#  IDENTITY_MAT=${TEST_DATA_FOLDER}/idendity_matrix.txt
#  BATCH_SIZE=10

# Example for corrField_step.config
# corrField_config_step1="-L 10x5 -a 1 -N 10x5"
# corrField_config_step2="-L 5x3 -a 0.5"
# effective_etch_step1="26"
# effective_etch_step2="16"

PROJ_ROOT=/proj_root
source ${PROJ_ROOT}/config.sh
source ${PROJ_ROOT}/corrField_step.config

SRC_ROOT=/src/thorax_pca
PYTHON_ENV=/opt/conda/envs/python37/bin/python
SRC_ROOT=/src/Thorax_non_rigid_combine
C3D_ROOT=${SRC_ROOT}/packages/c3d
corrField_ROOT=${SRC_ROOT}/packages/corrField
NIFYREG_ROOT=${SRC_ROOT}/packages/niftyreg/bin

OUTPUT_ROOT_FOLDER=${PROJ_ROOT}/output
OUTPUT_INTERP_FOLDER=${PROJ_ROOT}/interp
OUTPUT_JAC_DET_FOLDER=${PROJ_ROOT}/jac_det
mkdir -p ${OUTPUT_ROOT_FOLDER}
mkdir -p ${OUTPUT_INTERP_FOLDER}
mkdir -p ${OUTPUT_JAC_DET_FOLDER}

source ${SRC_ROOT}/tools/functions_corrField_2step.sh

run_scan_list_batch ${BATCH_SIZE}