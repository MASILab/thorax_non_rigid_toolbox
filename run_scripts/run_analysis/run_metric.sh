#!/bin/bash

# example file. Put this into the project root folder and run.

RUN_COMMAND="$(basename -- $1)"

PROJ_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

SINGULARITY_ROOT=${MY_NFS_DATA_ROOT}/singularity/thorax_combine/conda_base
SRC_ROOT=${SINGULARITY_ROOT}/src/Thorax_non_rigid_combine
PYTHON_ENV=${SINGULARITY_ROOT}/opt/conda/envs/python37/bin/python

NON_RIGID_ROOT=${PROJ_ROOT}/output/non_rigid
CORRFIELD_ROOT=${PROJ_ROOT}/corrField_root
ANALYSIS_ROOT=${PROJ_ROOT}/analysis

DATA_LIST=${PROJ_ROOT}/data/file_list
REFERENCE_ROOT=${PROJ_ROOT}/reference
NON_RIGID_INTERP_ROOT=${NON_RIGID_ROOT}/interp

ANALYSIS_DICE_ROOT=${ANALYSIS_ROOT}/dice
ANSLYSIS_SURFACE_ROOT=${ANALYSIS_ROOT}/surface_dist
DICE_VALID_REGION_MASK_FOLDER=${ANALYSIS_ROOT}/dice_effective_region
mkdir -p ${ANALYSIS_DICE_ROOT}
mkdir -p ${DICE_VALID_REGION_MASK_FOLDER}
mkdir -p ${ANSLYSIS_SURFACE_ROOT}

ANALYSIS_TEST_LIST=${ANALYSIS_ROOT}/analyze_test_list.txt
OUT_METRIC_BOX_FOLDER=${ANALYSIS_ROOT}/metric_plot
mkdir -p ${OUT_METRIC_BOX_FOLDER}

METRIC_TABLE_FOLDER=${ANALYSIS_ROOT}/metric_table
mkdir -p ${METRIC_TABLE_FOLDER}

METRIC_ETCH_RADIUS="16"

source ${SRC_ROOT}/tools/functions_dice_metric.sh
source ${SRC_ROOT}/tools/functions_surface_metric.sh
source ${SRC_ROOT}/tools/functions_general_metric.sh

${RUN_COMMAND}


