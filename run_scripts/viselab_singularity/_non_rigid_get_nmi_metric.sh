#!/bin/bash

source /src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh

SRC_ROOT=${NON_RIGID_SRC_ROOT}

PROJ_ROOT=/proj_root
REFERENCE_ROOT=${PROJ_ROOT}/reference
NON_RIGID_ROOT=${PROJ_ROOT}/output/non_rigid
NON_RIGID_INTERP_ROOT=${NON_RIGID_ROOT}/interp

ANALYSIS_ROOT=${PROJ_ROOT}/analysis
DATA_LIST=${ANALYSIS_ROOT}/file_list
ANALYSIS_METRIC_ROOT=${ANALYSIS_ROOT}/metric
ANALYSIS_MI_ROOT=${ANALYSIS_METRIC_ROOT}/mi
mkdir -p ${ANALYSIS_MI_ROOT}

MASKED_FOLDER=${ANALYSIS_ROOT}/gen_template/masked_folder

set -o xtrace
${PYTHON_ENV} ${SRC_ROOT}/tools/paral_metric_mi.py \
  --in-folder ${MASKED_FOLDER} \
  --ref-img ${REFERENCE_ROOT}/non_rigid.nii.gz \
  --file-list-txt ${DATA_LIST} \
  --niftyreg-root ${NIFYREG_ROOT} \
  --out-csv ${ANALYSIS_MI_ROOT}/nmi.csv \
  --num-process 25
set +o xtrace
