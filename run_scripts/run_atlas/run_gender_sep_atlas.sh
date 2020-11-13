#!/bin/bash

##################################################
# 3/17/2020 - Kaiwen
# Run gender specified atlas - just using 50 dataset each.
##################################################

CONFIG_FILE=$(readlink -f $1)
source ${CONFIG_FILE}
source ${NON_RIGID_SRC_ROOT}/tools/atlas_built_functions.sh

SPLIT_DATA_ROOT=${ATLAS_OUT_ROOT}/data

run_gender_atlas () {
  local gender_flag=$1

  local gender_out_root=${ATLAS_OUT_ROOT}/${gender_flag}
  mkdir -p ${gender_out_root}
  local gender_in_data_folder=${SPLIT_DATA_ROOT}/${gender_flag}
  local ref_masked_img=${SPLIT_DATA_ROOT}/reference/${gender_flag}.nii.gz
  local ref_thr_img=${SPLIT_DATA_ROOT}/reference/${gender_flag}_thr.nii.gz

  # 1. Generate configuration file for affine
  AFFINE_ROOT=${gender_out_root}/affine
  mkdir -p ${AFFINE_ROOT}
  AFFINE_CONFIG=${AFFINE_ROOT}/config.sh
#  generate_bash_config_scan \
#    ${AFFINE_CONFIG} \
#    ${gender_in_data_folder} \
#    ${AFFINE_ROOT} \
#    ${ref_thr_img}

  # 2. Execute affine.
#  ${AFFINE_SRC_ROOT}/run_reg_block.sh ${AFFINE_CONFIG}

  # 3. Post-process affine result.
  NON_RIGID_ROOT=${gender_out_root}/non_rigid
  mkdir -p ${NON_RIGID_ROOT}
  NON_RIGID_INPUT_FOLDER=${NON_RIGID_ROOT}/affine_result
  post_process_affine \
    ${AFFINE_ROOT}/interp/ori \
    ${TEMPLATE_MASK_IMG} \
    ${NON_RIGID_INPUT_FOLDER}

  # 4. Now do non-rigid with deeds
  NON_RIGID_OUT_TEMP_FOLDER=${NON_RIGID_ROOT}/temp
  NON_RIGID_OUT_WRAPPED_FOLDER=${NON_RIGID_ROOT}/wrapped
  run_deeds_non_rigid \
    ${NON_RIGID_INPUT_FOLDER} \
    ${NON_RIGID_OUT_TEMP_FOLDER} \
    ${NON_RIGID_OUT_WRAPPED_FOLDER} \
    ${ref_masked_img} \
    ${IDD_MAT}

  # 5. Generate the atlas
  OUT_TEMPLATE=${gender_out_root}/template.nii.gz
  set -o xtrace
  ${PYTHON_ENV} ${NON_RIGID_SRC_ROOT}/tools/average_images.py \
    --in_folder ${NON_RIGID_OUT_WRAPPED_FOLDER} \
    --out ${OUT_TEMPLATE} \
    --ref ${ref_masked_img} \
    --num_processes 10
  set +o xtrace
}

run_gender_atlas ${MALE_FLAG}
run_gender_atlas ${FEMALE_FLAG}