#!/bin/bash
FINE_TUNE_ROOT
PROJ_ROOT=/proj_root
source /src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh

NUM_PROCESS=50
SRC_ROOT=${NON_RIGID_SRC_ROOT}
ANALYSIS_FOLDER=${PROJ_ROOT}/analysis
FILE_LIST_TXT=${ANALYSIS_FOLDER}/file_list

REFERENCE_ROOT=${PROJ_ROOT}/output_low_res/reference
FINE_TUNE_ROOT=${ANALYSIS_FOLDER}/fine_tune_2_stages
TEST_OUTPUT_ROOT=${PROJ_ROOT}/fine_tune_root
ORI_FOLDER=${ANALYSIS_FOLDER}/ori_iso_resample_low_res
AFFINE_INTERP_ORI_FOLDER=${PROJ_ROOT}/output/affine/interp/ori_low_res

FINE_TUNE_DATA_FOLDER=${FINE_TUNE_ROOT}/data
mkdir -p ${FINE_TUNE_ROOT}
mkdir -p ${FINE_TUNE_DATA_FOLDER}

METRIC_ETCH_RADIUS="1"
THRES_VAL_LUNG="0.935"
THRES_VAL_BODY="0.990"
THRES_VAL_NEG_JAC_RATIO='0.01'

write_plot_test_info_csv () {
  local plot_test_list=$1
  local mask_flag=$2
  local column_flag=$3
  local out_csv_file=$4
  local csv_category=$5

  local num_project=$(cat ${plot_test_list} | wc -l )
  mapfile -t cmds_project_list < ${plot_test_list}

  echo "Number of projects ${num_project}"
  echo "Save csv file to ${out_csv_file}"

  > ${out_csv_file}
  echo "TestName,CSV,COLUMN,OUTLIER" >> ${out_csv_file}
  for i in $(seq 0 $((${num_project}-1)))
  do
    local test_name=${cmds_project_list[$i]}
    local csv_path=${FINE_TUNE_DATA_FOLDER}/${test_name}/${csv_category}/${mask_flag}.csv
#    local outlier_list_path=${FINE_TUNE_DATA_FOLDER}/${test_name}/outlier_list/${mask_flag}
#    local outlier_list_path=${FINE_TUNE_ROOT}/overlay_00000036time20140506.nii.gz/outlier_list
    local outlier_list_path=${FINE_TUNE_ROOT}/box_plot/outlier_list/${mask_flag}
    echo "${test_name},${csv_path},${column_flag},${outlier_list_path}" >> ${out_csv_file}
  done
}

get_box_outlier_plot () {
  local csv_path=$1
  local thres_val="$2"
  local out_fig=$3

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_combined_box_and_outlier_scatter_w_csv.py \
    --in-csv ${csv_path} \
    --thres-val ${thres_val} \
    --out-fig ${out_fig}
  set +o xtrace
}

write_plot_test_info_csv \
  ${FINE_TUNE_ROOT}/plot_proj_list \
  lung_mask \
  "Dice" \
  ${FINE_TUNE_ROOT}/box_lung_mask.csv \
  "dice"

write_plot_test_info_csv \
  ${FINE_TUNE_ROOT}/plot_proj_list \
  body_mask \
  "Dice" \
  ${FINE_TUNE_ROOT}/box_body_mask.csv \
  "dice"

write_plot_test_info_csv \
  ${FINE_TUNE_ROOT}/plot_proj_list \
  jac_statics \
  "NegRatio" \
  ${FINE_TUNE_ROOT}/box_jac_neg.csv \
  "jac"

#write_plot_test_info_csv \
#  ${FINE_TUNE_ROOT}/plot_proj_list \
#  body_mask \
#  "Dice" \
#  ${FINE_TUNE_ROOT}/box_body_mask.csv

BOX_PLOT_FOLDER=${FINE_TUNE_ROOT}/box_plot
mkdir -p ${BOX_PLOT_FOLDER}

get_box_outlier_plot \
  ${FINE_TUNE_ROOT}/box_lung_mask.csv \
  ${THRES_VAL_LUNG} \
  ${BOX_PLOT_FOLDER}/lung_mask.png

get_box_outlier_plot \
  ${FINE_TUNE_ROOT}/box_body_mask.csv \
  ${THRES_VAL_BODY} \
  ${BOX_PLOT_FOLDER}/body_mask.png

get_box_outlier_plot \
  ${FINE_TUNE_ROOT}/box_jac_neg.csv \
  ${THRES_VAL_NEG_JAC_RATIO} \
  ${BOX_PLOT_FOLDER}/jac_neg.png