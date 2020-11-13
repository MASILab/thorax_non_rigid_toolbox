#!/bin/bash

# Call this script using non_rigid_entry_point.sh
# example file. Put this into the project root folder and run.

#  Example for config.sh --

## Runtime enviroment
#SRC_ROOT=/src/Thorax_non_rigid_combine
#PYTHON_ENV=/opt/conda/envs/python37/bin/python
#IF_REMOVE_TEMP_FILES=false
#
## Tools
#TOOL_ROOT=${SRC_ROOT}/packages
#C3D_ROOT=${TOOL_ROOT}/c3d
#NIFYREG_ROOT=${TOOL_ROOT}/niftyreg/bin
#corrField_ROOT=${TOOL_ROOT}/corrField
#
## corrField configuration
#corrField_config_step1="-L 10x5 -a 1 -N 10x5"
#corrField_config_step2="-L 5x3 -a 0.5"
#corrField_config_step3="-L 10x5 -a 0.1 -N 10x5 -R 6x4"
#effective_etch_step1="26"
#effective_etch_step2="16"
#effective_etch_step3="16"
#
## Data
## MOVING_FOLDER=/proj_root/output/affine/interp/ori
#MOVING_FOLDER=/data_root/output/affine/interp/ori
#OUT_DATA_FOLDER=/proj_root
#MASK_FOLDER=/data_root/output/affine/interp
#REFERENCE_FOLDER=/data_root/reference
#FIXED_IMG=${REFERENCE_FOLDER}/non_rigid.nii.gz
#IDENTITY_MAT=${REFERENCE_FOLDER}/idendity_matrix.txt
#
#OUTPUT_ROOT_FOLDER=${OUT_DATA_FOLDER}/output
#OUTPUT_INTERP_FOLDER=${OUT_DATA_FOLDER}/interp
#OUTPUT_JAC_DET_FOLDER=${OUT_DATA_FOLDER}/jac_det
#
#set -o xtrace
#mkdir -p ${OUTPUT_ROOT_FOLDER}
#mkdir -p ${OUTPUT_INTERP_FOLDER}
#mkdir -p ${OUTPUT_JAC_DET_FOLDER}
#set +o xtrace

## config.sh end here

PROJ_ROOT=/proj_root
source ${PROJ_ROOT}/config.sh

export SRC_ROOT
export PROJ_ROOT
export OUTPUT_LOG
export N_JOBS

process_one_scan () {
  local scan_name="$1"

  ${SRC_ROOT}/run_scripts/run_non_rigid_single_scan.sh \
    ${PROJ_ROOT}/config.sh \
    ${scan_name}
}

export -f process_one_scan

set -o xtrace
parallel --results ${OUTPUT_LOG} -P ${N_JOBS} process_one_scan < ${FILE_LIST_TXT}
set +o xtrace