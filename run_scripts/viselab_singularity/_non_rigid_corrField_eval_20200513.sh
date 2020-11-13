#!/bin/bash

TEST_FLAG="$1"

PROJ_ROOT=/proj_root
source /src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh

SRC_ROOT=${NON_RIGID_SRC_ROOT}

#source ${PROJ_ROOT}/config.analysis.sh
# config.analysis.sh example
NUM_PROCESS=25
ANALYSIS_FOLDER=${PROJ_ROOT}/analysis
FILE_LIST_TXT=${ANALYSIS_FOLDER}/file_list

REFERENCE_ROOT=${PROJ_ROOT}/reference
TEST_OUTPUT_ROOT=${PROJ_ROOT}/output

#ORI_FOLDER=${ANALYSIS_FOLDER}/ori_iso_resample_low_res
AFFINE_INTERP_ORI_FOLDER=${PROJ_ROOT}/output/affine/interp/ori
ORI_FOLDER=${AFFINE_INTERP_ORI_FOLDER}

FINE_TUNE_DATA_FOLDER=${ANALYSIS_FOLDER}/data
mkdir -p ${FINE_TUNE_DATA_FOLDER}

METRIC_ETCH_RADIUS="1"
THRES_VAL_LUNG="0.935"
THRES_VAL_BODY="0.990"

IF_REMOVE_TEMP_FILES=true

generate_metric_data_test () {
  local test_flag="$1"

  local NON_RIGID_WARP_ORT_FOLDER=${TEST_OUTPUT_ROOT}/${test_flag}/interp/ori
  local EFFECTIVE_MASK_FOLDER=${TEST_OUTPUT_ROOT}/${test_flag}/interp/effective_region
  local MASKED_FOLDER=${FINE_TUNE_DATA_FOLDER}/${test_flag}/masked_folder
  mkdir -p ${MASKED_FOLDER}

  local NON_RIGID_INTERP_ROOT=${TEST_OUTPUT_ROOT}/${test_flag}/interp
  local DICE_VALID_REGION_MASK_FOLDER=${FINE_TUNE_DATA_FOLDER}/${test_flag}/dice_effective_region
  local ANALYSIS_DICE_ROOT=${FINE_TUNE_DATA_FOLDER}/${test_flag}/dice
  mkdir -p ${DICE_VALID_REGION_MASK_FOLDER}
  mkdir -p ${ANALYSIS_DICE_ROOT}
  local ANALYSIS_OUTLIER_ROOT=${FINE_TUNE_DATA_FOLDER}/${test_flag}/outlier_list
  mkdir -p ${ANALYSIS_OUTLIER_ROOT}

  get_overlapping_non_nan_region_mask () {
    # Get the overlapping non-nan region
    local overlap_non_nan_region_mask_folder=${TEST_OUTPUT_ROOT}/${test_flag}/interp/overlap_non_nan_region
    local warped_ori_non_nan_region_folder=${TEST_OUTPUT_ROOT}/${test_flag}/interp/ori_non_nan_region
    local fixed_non_nan_region_mask=${REFERENCE_ROOT}/valid_region_mask.nii.gz

    set -o xtrace
    mkdir -p ${warped_ori_non_nan_region_folder}
    ${PYTHON_ENV} ${SRC_ROOT}/tools/paral_non_nan_mask.py \
      --in-folder ${NON_RIGID_WARP_ORT_FOLDER} \
      --out-mask-folder ${warped_ori_non_nan_region_folder} \
      --file-list-txt ${FILE_LIST_TXT} \
      --num-process ${NUM_PROCESS}
    set +o xtrace

    set -o xtrace
    mkdir -p ${overlap_non_nan_region_mask_folder}
    ${PYTHON_ENV} ${SRC_ROOT}/tools/paral_apply_mask.py \
      --in-folder ${warped_ori_non_nan_region_folder} \
      --in-mask-file ${fixed_non_nan_region_mask} \
      --out-folder ${overlap_non_nan_region_mask_folder} \
      --file-list-txt ${FILE_LIST_TXT} \
      --ambient-val 0 \
      --num-process ${NUM_PROCESS}
    set +o xtrace
  }

#  get_effective_region_masked_image () {
#    # Get warped images masked by effective region.
#    local overlap_non_nan_region_mask_folder=${TEST_OUTPUT_ROOT}/${test_flag}/interp/overlap_non_nan_region
#    set -o xtrace
#    ${PYTHON_ENV} ${SRC_ROOT}/tools/paral_apply_mask.py \
#      --in-folder ${NON_RIGID_WARP_ORT_FOLDER} \
#      --in-mask-folder ${overlap_non_nan_region_mask_folder} \
#      --out-folder ${MASKED_FOLDER} \
#      --file-list-txt ${FILE_LIST_TXT} \
#      --ambient-val "nan" \
#      --num-process ${NUM_PROCESS}
#    set +o xtrace
#  }

  get_dice_with_effective_region_flag () {
    local mask_flag="$1"
    local dice_valid_region_mask_folder=${DICE_VALID_REGION_MASK_FOLDER}/${mask_flag}
    local in_mask_folder=${NON_RIGID_INTERP_ROOT}/${mask_flag}

    local ref_valid_region_mask=${REFERENCE_ROOT}/valid_region_mask.nii.gz
    local ref_gt_mask=${REFERENCE_ROOT}/${mask_flag}.nii.gz

    local out_csv=${ANALYSIS_DICE_ROOT}/${mask_flag}.csv

    local overlap_non_nan_region_mask_folder=${TEST_OUTPUT_ROOT}/${test_flag}/interp/overlap_non_nan_region

    set -o xtrace
    mkdir -p ${dice_valid_region_mask_folder}

    # No need for this one. TODO: replace with valid region mask of MASKED_FOLDER
#    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_dice_effective_region.py \
#      --in-ori-folder ${MASKED_FOLDER} \
#      --file-list-txt ${FILE_LIST_TXT} \
#      --in-ref-valid-mask ${ref_valid_region_mask} \
#      --out-folder ${dice_valid_region_mask_folder} \
#      --etch-radius ${METRIC_ETCH_RADIUS} \
#      --num-process ${NUM_PROCESS}

    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_dice_statics.py \
      --in-folder ${in_mask_folder} \
      --in-effective-mask-folder ${overlap_non_nan_region_mask_folder} \
      --file-list-txt ${FILE_LIST_TXT} \
      --gt-mask ${ref_gt_mask} \
      --out-csv ${out_csv} \
      --num-process ${NUM_PROCESS}
    set +o xtrace
  }

  get_outlier_list () {
    local mask_flag=$1
    local out_outlier_list=$2
    local thres_val="$3"
    local column_name="$4"

    local csv_file=${ANALYSIS_DICE_ROOT}/${mask_flag}.csv

    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/file_list_thres_less_than_csv.py \
      --in-csv ${csv_file} \
      --thres-val "${thres_val}" \
      --which-column "${column_name}" \
      --file-list-out ${out_outlier_list}
    set +o xtrace
  }

  get_jacobian_statics () {
    local JAC_DET_FOLDER=${TEST_OUTPUT_ROOT}/${test_flag}/jac_det
    local ANALYSIS_JAC_ROOT=${FINE_TUNE_DATA_FOLDER}/${test_flag}/jac
    mkdir -p ${ANALYSIS_JAC_ROOT}

    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_jacobian_statics.py \
      --in-jac-det-folder ${JAC_DET_FOLDER} \
      --file-list-txt ${FILE_LIST_TXT} \
      --out-csv ${ANALYSIS_JAC_ROOT}/jac_statics.csv \
      --num-process ${NUM_PROCESS}
    set +o xtrace
  }

  plot_overlay () {
    local file_list=$1
    local output_png_folder=$2

    local WARPED_FOLDER=${NON_RIGID_INTERP_ROOT}/ori
    mkdir -p ${output_png_folder}

    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/paral_overlay_multi_clips.py \
      --in-ori-folder ${ORI_FOLDER} \
      --in-affine-folder ${AFFINE_INTERP_ORI_FOLDER} \
      --in-warped-folder ${WARPED_FOLDER} \
      --ref-img ${REFERENCE_ROOT}/non_rigid.nii.gz \
      --file-list-txt ${file_list} \
      --out-png-folder ${output_png_folder} \
      --num-process ${NUM_PROCESS} \
      --step-axial 50 \
      --step-sagittal 75 \
      --step-coronal 30
    set +o xtrace
  }

#  get_effective_region_masked_image

#  get_overlapping_non_nan_region_mask
#  get_dice_with_effective_region_flag lung_mask
#  get_dice_with_effective_region_flag body_mask

#  get_outlier_list \
#    lung_mask \
#    ${ANALYSIS_OUTLIER_ROOT}/lung_mask \
#    ${THRES_VAL_LUNG} \
#    Dice
#  get_outlier_list \
#    body_mask \
#    ${ANALYSIS_OUTLIER_ROOT}/body_mask \
#    ${THRES_VAL_BODY} \
#    Dice

#  get_jacobian_statics

  plot_overlay \
    ${FILE_LIST_TXT} \
    ${FINE_TUNE_DATA_FOLDER}/${test_flag}/overlay
}

generate_metric_data_test ${TEST_FLAG}

#if [ "$IF_REMOVE_TEMP_FILES" = true ] ; then
#  set -o xtrace
#  rm -rf ${FINE_TUNE_DATA_FOLDER}/${TEST_FLAG}/masked_folder
#  rm -rf ${FINE_TUNE_DATA_FOLDER}/${TEST_FLAG}/dice_effective_region
#  set +o xtrace
#fi