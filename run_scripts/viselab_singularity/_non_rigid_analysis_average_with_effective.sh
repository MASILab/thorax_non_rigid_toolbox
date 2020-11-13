#!/bin/bash

source /src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh

ANALYSIS_FOLDER=${PROJ_ROOT}/analysis
NON_RIGID_WARP_ORT_FOLDER=${PROJ_ROOT}/output/non_rigid/interp/ori
EFFECTIVE_MASK_FOLDER=${PROJ_ROOT}/output/non_rigid/interp/effective_region
MASKED_FOLDER=${ANALYSIS_FOLDER}/gen_template/masked_folder

#FILE_LIST_TXT=${ANALYSIS_FOLDER}/file_list
#AVERAGE_TEMPLATE_FOLDER=${ANALYSIS_FOLDER}/gen_template/template

FILE_LIST_TXT=${ANALYSIS_FOLDER}/metric/QA_result.txt
AVERAGE_TEMPLATE_FOLDER=${ANALYSIS_FOLDER}/gen_template/template_QA

set -o xtrace
mkdir -p ${ANALYSIS_FOLDER}
mkdir -p ${MASKED_FOLDER}
mkdir -p ${AVERAGE_TEMPLATE_FOLDER}

#${PYTHON_ENV} ${NON_RIGID_SRC_ROOT}/tools/paral_apply_mask.py \
#  --in-folder ${NON_RIGID_WARP_ORT_FOLDER} \
#  --in-mask-folder ${EFFECTIVE_MASK_FOLDER} \
#  --out-folder ${MASKED_FOLDER} \
#  --file-list-txt ${FILE_LIST_TXT} \
#  --ambient-val "nan" \
#  --num-process 25

${PYTHON_ENV} ${NON_RIGID_SRC_ROOT}/tools/paral_average.py \
  --in-folder ${MASKED_FOLDER} \
  --out-folder ${AVERAGE_TEMPLATE_FOLDER} \
  --file-list-txt ${FILE_LIST_TXT} \
  --num-process 60
set +o xtrace