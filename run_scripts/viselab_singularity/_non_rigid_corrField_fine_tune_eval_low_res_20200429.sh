#!/bin/bash

PROJ_ROOT=/proj_root
source /src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh

NUM_PROCESS=50
SRC_ROOT=${NON_RIGID_SRC_ROOT}
ANALYSIS_FOLDER=${PROJ_ROOT}/analysis
FILE_LIST_TXT=${ANALYSIS_FOLDER}/file_list

#REFERENCE_ROOT=${PROJ_ROOT}/reference
#FINE_TUNE_ROOT=${ANALYSIS_FOLDER}/fine_tune
#TEST_OUTPUT_ROOT=${PROJ_ROOT}/output

REFERENCE_ROOT=${PROJ_ROOT}/output_low_res/reference
FINE_TUNE_ROOT=${ANALYSIS_FOLDER}/fine_tune_low_res
TEST_OUTPUT_ROOT=${PROJ_ROOT}/output_low_res
ORI_FOLDER=${ANALYSIS_FOLDER}/ori_iso_resample_low_res
AFFINE_INTERP_ORI_FOLDER=${PROJ_ROOT}/output/affine/interp/ori_low_res

FINE_TUNE_DATA_FOLDER=${FINE_TUNE_ROOT}/data
mkdir -p ${FINE_TUNE_ROOT}
mkdir -p ${FINE_TUNE_DATA_FOLDER}

METRIC_ETCH_RADIUS="1"
THRES_VAL_LUNG="0.935"
THRES_VAL_BODY="0.990"

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

  get_effective_region_masked_image () {
    # Get warped images masked by effective region.
    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/paral_apply_mask.py \
      --in-folder ${NON_RIGID_WARP_ORT_FOLDER} \
      --in-mask-folder ${EFFECTIVE_MASK_FOLDER} \
      --out-folder ${MASKED_FOLDER} \
      --file-list-txt ${FILE_LIST_TXT} \
      --ambient-val "nan" \
      --num-process ${NUM_PROCESS}
    set +o xtrace
  }

  get_dice_with_effective_region_flag () {
    local mask_flag="$1"
    local dice_valid_region_mask_folder=${DICE_VALID_REGION_MASK_FOLDER}/${mask_flag}
    local in_mask_folder=${NON_RIGID_INTERP_ROOT}/${mask_flag}

    local ref_valid_region_mask=${REFERENCE_ROOT}/valid_region_mask.nii.gz
    local ref_gt_mask=${REFERENCE_ROOT}/${mask_flag}.nii.gz

    local out_csv=${ANALYSIS_DICE_ROOT}/${mask_flag}.csv

    set -o xtrace
    mkdir -p ${dice_valid_region_mask_folder}

    # No need for this one. TODO: replace with valid region mask of MASKED_FOLDER
    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_dice_effective_region.py \
      --in-ori-folder ${MASKED_FOLDER} \
      --file-list-txt ${FILE_LIST_TXT} \
      --in-ref-valid-mask ${ref_valid_region_mask} \
      --out-folder ${dice_valid_region_mask_folder} \
      --etch-radius ${METRIC_ETCH_RADIUS} \
      --num-process ${NUM_PROCESS}

    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_dice_statics.py \
      --in-folder ${in_mask_folder} \
      --in-effective-mask-folder ${dice_valid_region_mask_folder} \
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
      --num-process ${NUM_PROCESS}
    set +o xtrace
  }

#  get_effective_region_masked_image
#
#  get_dice_with_effective_region_flag lung_mask
#  get_dice_with_effective_region_flag body_mask
#
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
#
#  get_jacobian_statics

  plot_overlay \
    ${FILE_LIST_TXT} \
    ${FINE_TUNE_DATA_FOLDER}/${test_flag}/overlay
  plot_overlay \
    ${ANALYSIS_OUTLIER_ROOT}/lung_mask \
    ${FINE_TUNE_DATA_FOLDER}/${test_flag}/overlay_outlier/lung
  plot_overlay \
    ${ANALYSIS_OUTLIER_ROOT}/body_mask \
    ${FINE_TUNE_DATA_FOLDER}/${test_flag}/overlay_outlier/body
}

get_box_outlier_plot () {
  local mask_flag="$1"
  local thres_val="$2"
  local out_fig=$3
  local num_complete_test="$4"

  local CSV_BASELINE=${FINE_TUNE_DATA_FOLDER}/baseline/dice/${mask_flag}.csv
  local CSV_1=${FINE_TUNE_DATA_FOLDER}/cap_range_80/dice/${mask_flag}.csv
  local CSV_2=${FINE_TUNE_DATA_FOLDER}/step_3_1/dice/${mask_flag}.csv
  local CSV_3=${FINE_TUNE_DATA_FOLDER}/step_2_5/dice/${mask_flag}.csv
  local CSV_4=${FINE_TUNE_DATA_FOLDER}/step_2_3/dice/${mask_flag}.csv
  local CSV_5=${FINE_TUNE_DATA_FOLDER}/step_2_4/dice/${mask_flag}.csv

  local OUTLIER_BASELINE=${FINE_TUNE_DATA_FOLDER}/baseline/outlier_list/${mask_flag}
  local OUTLIER_1=${FINE_TUNE_DATA_FOLDER}/cap_range_80/outlier_list/${mask_flag}
  local OUTLIER_2=${FINE_TUNE_DATA_FOLDER}/step_3_1/outlier_list/${mask_flag}
  local OUTLIER_3=${FINE_TUNE_DATA_FOLDER}/step_2_5/outlier_list/${mask_flag}
  local OUTLIER_4=${FINE_TUNE_DATA_FOLDER}/step_2_3/outlier_list/${mask_flag}
  local OUTLIER_5=${FINE_TUNE_DATA_FOLDER}/step_2_4/outlier_list/${mask_flag}

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_combined_box_and_outlier_scatter.py \
    --csv-data-baseline ${CSV_BASELINE} \
    --csv-data-1 ${CSV_1} \
    --csv-data-2 ${CSV_2} \
    --csv-data-3 ${CSV_3} \
    --csv-data-4 ${CSV_4} \
    --csv-data-5 ${CSV_5} \
    --outlier-list-baseline ${OUTLIER_BASELINE} \
    --outlier-list-1 ${OUTLIER_1} \
    --outlier-list-2 ${OUTLIER_2} \
    --outlier-list-3 ${OUTLIER_3} \
    --outlier-list-4 ${OUTLIER_4} \
    --outlier-list-5 ${OUTLIER_5} \
    --column 'Dice' \
    --thres-val ${thres_val} \
    --out-fig ${out_fig} \
    --num-complete-test ${num_complete_test}
  set +o xtrace
}

get_box_scatter_plot_jac () {
  local thres_val="$1"
  local out_fig=$2
  local num_complete_test="$3"
  local column_flag="$4"

  local CSV_BASELINE=${FINE_TUNE_DATA_FOLDER}/baseline/jac/jac_statics.csv
  local CSV_1=${FINE_TUNE_DATA_FOLDER}/cap_range_80/jac/jac_statics.csv
  local CSV_2=${FINE_TUNE_DATA_FOLDER}/step_3_1/jac/jac_statics.csv
  local CSV_3=${FINE_TUNE_DATA_FOLDER}/step_2_5/jac/jac_statics.csv
  local CSV_4=${FINE_TUNE_DATA_FOLDER}/step_2_3/jac/jac_statics.csv
  local CSV_5=${FINE_TUNE_DATA_FOLDER}/step_2_4/jac/jac_statics.csv

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_combined_box_and_outlier_scatter_jac_det.py \
    --csv-data-baseline ${CSV_BASELINE} \
    --csv-data-1 ${CSV_1} \
    --csv-data-2 ${CSV_2} \
    --csv-data-3 ${CSV_3} \
    --csv-data-4 ${CSV_4} \
    --csv-data-5 ${CSV_5} \
    --column ${column_flag} \
    --thres-val ${thres_val} \
    --out-fig ${out_fig} \
    --num-complete-test ${num_complete_test}
  set +o xtrace
}

get_dist_distribution () {
  local DIST_TABLE=${ANALYSIS_FOLDER}/metric/dist_table.csv
  local OUTLIER_LIST_1=${ANALYSIS_FOLDER}/metric/outlier_list/lung.txt
  local OUTLIER_LIST_2=${ANALYSIS_FOLDER}/metric/outlier_list/body.txt
  local OUT_FIG=${ANALYSIS_FOLDER}/metric/dist_distribution.png
  local SEARCH_RADIUS="40"

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_combined_box_and_outlier_scatter_distance.py \
    --csv-data ${DIST_TABLE} \
    --outlier-list-1 ${OUTLIER_LIST_1} \
    --outlier-list-2 ${OUTLIER_LIST_2} \
    --out-fig ${OUT_FIG} \
    --thres-val ${SEARCH_RADIUS}
  set +o xtrace
}



NUM_TEST_COMPLETE=2

#generate_metric_data_test baseline
#generate_metric_data_test baseline_0_ambient
#generate_metric_data_test step_1
#generate_metric_data_test step_1_2
#generate_metric_data_test step_1_3
#generate_metric_data_test step_1_4
#generate_metric_data_test step_1_5
#generate_metric_data_test step_1_6
#generate_metric_data_test step_2_1
#generate_metric_data_test step_2_2
#generate_metric_data_test step_2_3
#generate_metric_data_test step_2_4
#generate_metric_data_test step_2_5
#generate_metric_data_test step_3_1
#generate_metric_data_test baseline
generate_metric_data_test cap_range_80


#get_box_outlier_plot \
#  lung_mask \
#  ${THRES_VAL_LUNG} \
#  ${FINE_TUNE_ROOT}/lung.png \
#  ${NUM_TEST_COMPLETE}
#
#get_box_outlier_plot \
#  body_mask \
#  ${THRES_VAL_BODY} \
#  ${FINE_TUNE_ROOT}/body.png \
#  ${NUM_TEST_COMPLETE}
#
## The neg det ratio
#get_box_scatter_plot_jac \
#  "0.005" \
#  ${FINE_TUNE_ROOT}/jac_neg_ratio.png \
#  ${NUM_TEST_COMPLETE} \
#  "NegRatio"
#
## STD of jac det
#get_box_scatter_plot_jac \
#  "0.5" \
#  ${FINE_TUNE_ROOT}/jac_std.png \
#  ${NUM_TEST_COMPLETE} \
#  "STD"

#get_dist_distribution

