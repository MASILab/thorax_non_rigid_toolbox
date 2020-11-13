#!/bin/bash

# v4 - design to scale to 25, 50 dataset.

PROJ_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source ${PROJ_ROOT}/config.sh

#  Example for config.sh --
#  TEST_DATA_FOLDER=${PROJ_ROOT}/data
#  MOVING_FOLDER=${PROJ_ROOT}/../../output/affine/interp/ori
#  MASK_FOLDER=${PROJ_ROOT}/../../output/affine/interp
#  FILE_LIST=${PROJ_ROOT}/../../data/file_list
#  FIXED_IMG=${TEST_DATA_FOLDER}/fixed.nii.gz
#  MASK_IMG=${TEST_DATA_FOLDER}/mask_body_wall.nii.gz
#  IDENTITY_MAT=${TEST_DATA_FOLDER}/idendity_matrix.txt
#  BATCH_SIZE=10

SINGULARITY_ROOT=${MY_NFS_DATA_ROOT}/singularity/thorax_combine/conda_base
PYTHON_ENV=${SINGULARITY_ROOT}/opt/conda/envs/python37/bin/python
SRC_ROOT=${SINGULARITY_ROOT}/src/Thorax_non_rigid_combine
C3D_ROOT=${SRC_ROOT}/packages/c3d
corrField_ROOT=${SRC_ROOT}/packages/corrField
NIFYREG_ROOT=${SRC_ROOT}/packages/niftyreg/bin

OUTPUT_ROOT_FOLDER=${PROJ_ROOT}/output
OUTPUT_INTERP_FOLDER=${PROJ_ROOT}/interp
mkdir -p ${OUTPUT_ROOT_FOLDER}
mkdir -p ${OUTPUT_INTERP_FOLDER}

source ${SRC_ROOT}/tools/functions_corrField_3step.sh

run_scan_list_batch ${BATCH_SIZE}