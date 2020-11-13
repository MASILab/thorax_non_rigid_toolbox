#!/bin/bash

source /src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh

SRC_ROOT=${NON_RIGID_SRC_ROOT}

PROJ_ROOT=/proj_root
REFERENCE_ROOT=${PROJ_ROOT}/reference
NON_RIGID_ROOT=${PROJ_ROOT}/output/non_rigid
NON_RIGID_INTERP_ROOT=${NON_RIGID_ROOT}/interp
AFFINE_ROOT=${PROJ_ROOT}/output/affine
AFFINE_INTERP_ROOT=${AFFINE_ROOT}/interp

ANALYSIS_ROOT=${PROJ_ROOT}/analysis
DATA_LIST=${ANALYSIS_ROOT}/file_list
ANALYSIS_METRIC_ROOT=${ANALYSIS_ROOT}/metric
ANALYSIS_DICE_ROOT=${ANALYSIS_METRIC_ROOT}/dice
ANALYSIS_MI_ROOT=${ANALYSIS_METRIC_ROOT}/mi
mkdir -p ${ANALYSIS_MI_ROOT}

CSV_LUNG_DICE=${ANALYSIS_DICE_ROOT}/lung_mask.csv
CSV_BODY_DICE=${ANALYSIS_DICE_ROOT}/body_mask.csv
CSV_NMI=${ANALYSIS_MI_ROOT}/nmi.csv

# File lists
OUTLIER_LIST_ROOT=${ANALYSIS_METRIC_ROOT}/outlier_list
OUTLIER_LIST_LUNG=${OUTLIER_LIST_ROOT}/lung.txt
OUTLIER_LIST_BODY=${OUTLIER_LIST_ROOT}/body.txt
OUTLIER_LIST_NMI=${OUTLIER_LIST_ROOT}/nmi.txt
OUTLIER_LIST_QA=${OUTLIER_LIST_ROOT}/manual.txt
NORMAL_CASE_LIST=${ANALYSIS_ROOT}/metric/QA_result.txt

OUTLIER_PLOT_ROOT=${ANALYSIS_METRIC_ROOT}/outlier_plot
mkdir -p ${OUTLIER_PLOT_ROOT}

OUTLIER_OVERLAY_PLOT_ROOT=${ANALYSIS_METRIC_ROOT}/overlay_plot
mkdir -p ${OUTLIER_OVERLAY_PLOT_ROOT}

# Original, warped and reference.
AFFINE_INTERP_ORI_FOLDER=${AFFINE_INTERP_ROOT}/ori
MASKED_WARPED_FOLDER=${ANALYSIS_ROOT}/gen_template/masked_folder
REFERENCE_ROOT=${PROJ_ROOT}/reference

ORI_FOLDER=${ANALYSIS_ROOT}/ori_iso_resample

plot_overlay_outlier_list () {
  local outlier_list=$1
  local output_png_folder=$2

  set -o xtrace
  mkdir -p ${output_png_folder}

  ${PYTHON_ENV} ${SRC_ROOT}/tools/paral_overlay_multi_clips.py \
    --in-ori-folder ${ORI_FOLDER} \
    --in-affine-folder ${AFFINE_INTERP_ORI_FOLDER} \
    --in-warped-folder ${MASKED_WARPED_FOLDER} \
    --ref-img ${REFERENCE_ROOT}/non_rigid.nii.gz \
    --file-list-txt ${outlier_list} \
    --out-png-folder ${output_png_folder} \
    --num-process 20
  set +o xtrace
}

#plot_overlay_outlier_list \
#  ${OUTLIER_LIST_QA} \
#  ${OUTLIER_OVERLAY_PLOT_ROOT}/manual_QA

#plot_overlay_outlier_list \
#  ${OUTLIER_LIST_NMI} \
#  ${OUTLIER_OVERLAY_PLOT_ROOT}/nmi

#plot_overlay_outlier_list \
#  ${OUTLIER_LIST_LUNG} \
#  ${OUTLIER_OVERLAY_PLOT_ROOT}/lung_mask
#
#plot_overlay_outlier_list \
#  ${OUTLIER_LIST_BODY} \
#  ${OUTLIER_OVERLAY_PLOT_ROOT}/body_mask
#
#plot_overlay_outlier_list \
#  ${NORMAL_CASE_LIST} \
#  ${OUTLIER_OVERLAY_PLOT_ROOT}/normal

plot_overlay_outlier_list \
  ${DATA_LIST} \
  ${OUTLIER_OVERLAY_PLOT_ROOT}/normal