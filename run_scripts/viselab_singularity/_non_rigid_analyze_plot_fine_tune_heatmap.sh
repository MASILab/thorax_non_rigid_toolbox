#!/bin/bash

source /src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh

SRC_ROOT=${NON_RIGID_SRC_ROOT}

PROJ_ROOT=/proj_root
ANALYSIS_ROOT=${PROJ_ROOT}/analysis

ARCHIVE_FOLDER=${ANALYSIS_ROOT}/fine_tune_2_stages/archive
HEATMAP_FOLDER=${ANALYSIS_ROOT}/fine_tune_2_stages/heatmap_stage_1
#HEATMAP_FOLDER=${ANALYSIS_ROOT}/fine_tune_2_stages/heatmap_step1_4_1_2_1
#HEATMAP_FOLDER=${ANALYSIS_ROOT}/fine_tune_2_stages/heatmap_stage_1_extend1
#HEATMAP_FOLDER=${ANALYSIS_ROOT}/fine_tune_2_stages/heatmap_stage_1_extend1_fullmap
#HEATMAP_FOLDER=${ANALYSIS_ROOT}/fine_tune_2_stages/heatmap_stage_2
TEST_DATA_CSV=${HEATMAP_FOLDER}/data_list.csv
mkdir -p ${HEATMAP_FOLDER}
THRES_VAL_LUNG="0.935"
#THRES_VAL_BODY="0.990"
#THRES_VAL_BODY="0.992"
#THRES_VAL_BODY="0.993"
THRES_VAL_BODY="0.985"
THRES_VAL_NEG_JAC_RATIO='0.005'

set -o xtrace
${PYTHON_ENV} ${SRC_ROOT}/tools/get_plot_fine_tune_grid_heatmap.py \
  --in-archive-folder ${ARCHIVE_FOLDER} \
  --thres-lung-dice ${THRES_VAL_LUNG} \
  --thres-body-dice ${THRES_VAL_BODY} \
  --thres-jac-neg-ratio ${THRES_VAL_NEG_JAC_RATIO} \
  --out-png-folder ${HEATMAP_FOLDER} \
  --save-csv-path ${TEST_DATA_CSV} \
  --test-prefix "step1"
set +o xtrace