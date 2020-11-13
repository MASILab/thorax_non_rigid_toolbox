#!/bin/bash

source /src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh

ANALYSIS_FOLDER=${PROJ_ROOT}/analysis
NON_RIGID_WARP_ORT_FOLDER=${PROJ_ROOT}/output/non_rigid/interp/ori
EFFECTIVE_MASK_FOLDER=${PROJ_ROOT}/output/non_rigid/interp/effective_region
MASKED_FOLDER=${ANALYSIS_FOLDER}/gen_template/masked_folder

FILE_LIST_TXT=${ANALYSIS_FOLDER}/file_list

ANALYSIS_METRIC_ROOT=${ANALYSIS_FOLDER}/metric
OUTLIER_INCLUDE_LIST_FOLDER=${ANALYSIS_METRIC_ROOT}/outlier_list_include
OUTLIER_TOTAL_LIST=${ANALYSIS_METRIC_ROOT}/outlier_total.txt
QA_RESULT_LIST=${ANALYSIS_METRIC_ROOT}/QA_result.txt

set -o xtrace
${PYTHON_ENV} ${NON_RIGID_SRC_ROOT}/tools/file_list_combine.py \
  --file-list-folder ${OUTLIER_INCLUDE_LIST_FOLDER} \
  --out-file-list ${OUTLIER_TOTAL_LIST}

${PYTHON_ENV} ${NON_RIGID_SRC_ROOT}/tools/file_list_not_in.py \
  --file-list-total ${FILE_LIST_TXT} \
  --file-list-exclude ${OUTLIER_TOTAL_LIST} \
  --file-list-out ${QA_RESULT_LIST}
set +o xtrace