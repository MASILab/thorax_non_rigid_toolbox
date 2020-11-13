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
ANALYSIS_DICE_ROOT=${ANALYSIS_METRIC_ROOT}/dice
ANALYSIS_MI_ROOT=${ANALYSIS_METRIC_ROOT}/mi
mkdir -p ${ANALYSIS_MI_ROOT}

CSV_LUNG_DICE=${ANALYSIS_DICE_ROOT}/lung_mask.csv
CSV_BODY_DICE=${ANALYSIS_DICE_ROOT}/body_mask.csv
CSV_NMI=${ANALYSIS_MI_ROOT}/nmi.csv

OUTLIER_LIST_ROOT=${ANALYSIS_METRIC_ROOT}/outlier_list
mkdir -p ${OUTLIER_LIST_ROOT}
OUTLIER_LIST_LUNG=${OUTLIER_LIST_ROOT}/lung.txt
OUTLIER_LIST_BODY=${OUTLIER_LIST_ROOT}/body.txt
OUTLIER_LIST_NMI=${OUTLIER_LIST_ROOT}/nmi.txt
OUTLIER_LIST_QA=${OUTLIER_LIST_ROOT}/manual.txt

OUTLIER_PLOT_ROOT=${ANALYSIS_METRIC_ROOT}/outlier_plot
mkdir -p ${OUTLIER_PLOT_ROOT}

THRES_VAL_LUNG="0.935"
THRES_VAL_BODY="0.990"
THRES_VAL_NMI="1.180"

get_outlier_list () {
  local csv_file=$1
  local out_outlier_list=$2
  local thres_val="$3"
  local column_name="$4"

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/file_list_thres_less_than_csv.py \
    --in-csv ${csv_file} \
    --thres-val "${thres_val}" \
    --which-column "${column_name}" \
    --file-list-out ${out_outlier_list}
  set +o xtrace
}

get_box_scatter_plot () {
  local csv_path="$1"
  local column_name="$2"
  local out_fig="$3"
  local thres_val="$4"

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_combined_box_and_scatter.py \
    --csv-data ${csv_path} \
    --column ${column_name} \
    --out-fig ${out_fig} \
    --outlier-list-lung-dice ${OUTLIER_LIST_LUNG} \
    --outlier-list-body-dice ${OUTLIER_LIST_BODY} \
    --outlier-list-nmi ${OUTLIER_LIST_NMI} \
    --outlier-list-manual ${OUTLIER_LIST_QA} \
    --thres-val ${thres_val}
  set +o xtrace
}

get_outlier_list \
  ${CSV_LUNG_DICE} \
  ${OUTLIER_LIST_LUNG} \
  ${THRES_VAL_LUNG} \
  Dice

get_outlier_list \
  ${CSV_BODY_DICE} \
  ${OUTLIER_LIST_BODY} \
  ${THRES_VAL_BODY} \
  Dice

#get_box_scatter_plot \
#  ${CSV_LUNG_DICE} \
#  Dice \
#  ${OUTLIER_PLOT_ROOT}/lung.png \
#  0.935
#
#get_box_scatter_plot \
#  ${CSV_BODY_DICE} \
#  Dice \
#  ${OUTLIER_PLOT_ROOT}/body.png \
#  0.990
#
#get_box_scatter_plot \
#  ${CSV_NMI} \
#  NMI \
#  ${OUTLIER_PLOT_ROOT}/nmi.png \
#  1.180