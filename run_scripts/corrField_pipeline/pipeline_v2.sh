#!/bin/bash

RUN_CMD="$(basename -- $1)"

PYTHON_ENV=/nfs/masi/xuk9/singularity/thorax_combine/conda_base/opt/conda/envs/python37/bin/python
SRC_ROOT=/nfs/masi/xuk9/singularity/thorax_combine/conda_base/src/Thorax_non_rigid_combine
C3D_ROOT=${SRC_ROOT}/packages/c3d
corrField_ROOT=/home-nfs2/local/VANDERBILT/xuk9/local/corrField/bin
NIFYREG_ROOT=/home-nfs2/local/VANDERBILT/xuk9/local/niftyreg/bin

PROJ_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TEST_DATA_FOLDER=${PROJ_ROOT}/data
MOVING_IMG=${TEST_DATA_FOLDER}/moving.nii.gz
FIXED_IMG=${TEST_DATA_FOLDER}/fixed.nii.gz
MASK_IMG=${TEST_DATA_FOLDER}/mask.nii.gz
IDENTITY_MAT=${TEST_DATA_FOLDER}/idendity_matrix.txt

OUTPUT_LOW_RES_FOLDER=${PROJ_ROOT}/output_low_res
OUTPUT_LOW_RES_2_FOLDER=${PROJ_ROOT}/output_low_res2
OUTPUT_HIGH_RES_FOLDER=${PROJ_ROOT}/output_high_res
OUTPUT_JAC_FOLDER=${PROJ_ROOT}/jac
mkdir -p ${OUTPUT_LOW_RES_FOLDER}
mkdir -p ${OUTPUT_LOW_RES_2_FOLDER}
mkdir -p ${OUTPUT_HIGH_RES_FOLDER}
mkdir -p ${OUTPUT_JAC_FOLDER}

run_registration_pipeline () {
  # 1. Run low resolution
  run_low_res_1 () {
    set -o xtrace
    ${C3D_ROOT}/c3d -int 0 \
      ${MASK_IMG} -resample-mm 2x2x2mm \
      -o ${OUTPUT_LOW_RES_FOLDER}/mask.nii.gz
    ${NIFYREG_ROOT}/reg_resample -inter 3 -pad NaN \
      -ref ${OUTPUT_LOW_RES_FOLDER}/mask.nii.gz \
      -flo ${MOVING_IMG} \
      -trans ${IDENTITY_MAT} \
      -res ${OUTPUT_LOW_RES_FOLDER}/moving.nii.gz
    set +o xtrace
    run_registration_pipeline_res ${OUTPUT_LOW_RES_FOLDER} "-L 10x5 -a 1 -N 10x5" "26"
  }

  # 2. Run with updated mask still with low resolution.
  run_low_res_2 () {
    set -o xtrace
    ln -sf ${OUTPUT_LOW_RES_FOLDER}/mask.nii.gz ${OUTPUT_LOW_RES_2_FOLDER}/mask.nii.gz
    ln -sf ${OUTPUT_LOW_RES_FOLDER}/output/warp.nii.gz ${OUTPUT_LOW_RES_2_FOLDER}/moving.nii.gz
    set +o xtrace
    run_registration_pipeline_res ${OUTPUT_LOW_RES_2_FOLDER} "-L 5x3 -a 0.5" "16"
  }

  # 3. Run with high resolution, with more control on stability.
  run_high_res () {
    set -o xtrace
    ln -sf ${MASK_IMG} ${OUTPUT_HIGH_RES_FOLDER}/mask.nii.gz
    ${NIFYREG_ROOT}/reg_transform \
      -comp \
      ${OUTPUT_LOW_RES_FOLDER}/output/trans.nii.gz \
      ${OUTPUT_LOW_RES_2_FOLDER}/output/trans.nii.gz \
      ${OUTPUT_HIGH_RES_FOLDER}/trans_combine.nii.gz
    ${NIFYREG_ROOT}/reg_resample -inter 3 -pad NaN \
      -ref ${MASK_IMG} \
      -flo ${MOVING_IMG} \
      -trans ${OUTPUT_HIGH_RES_FOLDER}/trans_combine.nii.gz \
      -res ${OUTPUT_HIGH_RES_FOLDER}/moving.nii.gz
    set +o xtrace
    run_registration_pipeline_res ${OUTPUT_HIGH_RES_FOLDER} "-L 10x5 -a 0.1 -N 10x5 -R 6x4" "26"
  }

  run_combined_jacobian_analysis () {
    set -o xtrace
    ${NIFYREG_ROOT}/reg_transform \
      -comp \
      ${OUTPUT_HIGH_RES_FOLDER}/trans_combine.nii.gz \
      ${OUTPUT_HIGH_RES_FOLDER}/output/trans.nii.gz \
      ${OUTPUT_JAC_FOLDER}/trans_combine.nii.gz

    ${NIFYREG_ROOT}/reg_jacobian \
      -trans ${OUTPUT_JAC_FOLDER}/trans_combine.nii.gz \
      -ref ${MASK_IMG} \
      -jac ${OUTPUT_JAC_FOLDER}/jac.nii.gz

    ${NIFYREG_ROOT}/reg_resample -inter 3 \
      -ref ${MASK_IMG} \
      -flo ${OUTPUT_JAC_FOLDER}/jac.nii.gz \
      -res ${OUTPUT_JAC_FOLDER}/jac_full_res.nii.gz

    ${C3D_ROOT}/c3d \
      ${OUTPUT_JAC_FOLDER}/jac_full_res.nii.gz \
      -threshold -inf 0 1 0 -o ${OUTPUT_JAC_FOLDER}/neg_jac_map.nii.gz

    ${C3D_ROOT}/c3d \
      -verbose \
      ${OUTPUT_JAC_FOLDER}/neg_jac_map.nii.gz \
      ${OUTPUT_HIGH_RES_FOLDER}/output/effective_mask.nii.gz \
      -overlap 1
    set +o xtrace
  }

#  run_low_res_1
#  run_low_res_2
#  run_high_res
  run_combined_jacobian_analysis
}

run_registration_pipeline_res () {
  local root_folder=$1
  local corrField_opt="$2"
  local hw="$3"

  local mask=${root_folder}/mask.nii.gz
#  local moving=${root_folder}/moving.nii.gz

  local preprocess_folder=${root_folder}/preprocess
  local output_folder=${root_folder}/output
  mkdir -p ${preprocess_folder}
  mkdir -p ${output_folder}

  local fixed=${root_folder}/fixed.nii.gz

  echo ""
  echo "Create resampled fixed"
  set -o xtrace
  ${NIFYREG_ROOT}/reg_resample -inter 3 -pad NaN \
    -ref ${mask} \
    -flo ${FIXED_IMG} \
    -trans ${IDENTITY_MAT} \
    -res ${fixed}
  set +o xtrace

  run_preprocessing () {
    local scan_flag=$1

    local in_scan=${root_folder}/${scan_flag}.nii.gz
    local out_valid_region_mask=${preprocess_folder}/${scan_flag}_valid_region.nii.gz
    local out_signed_distance=${preprocess_folder}/${scan_flag}_edt.nii.gz

    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_non_nan_region.py \
      --ori ${in_scan} \
      --out-mask ${out_valid_region_mask}

    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_distance_field.py \
      --mask ${out_valid_region_mask} \
      --out-edt ${out_signed_distance}

    ${PYTHON_ENV} ${SRC_ROOT}/tools/replace_nan.py \
      --val 0 \
      --in_image ${in_scan} \
      --out_image ${preprocess_folder}/${scan_flag}_no_nan.nii.gz
    set +o xtrace
  }

  echo ""
  echo "Run preprocessing"
  run_preprocessing "moving"
  run_preprocessing "fixed"

  get_effective_region () {
    local in_edt_map=$1
    local distance="$2"
    local out_effective_region_mask=$3

    set -o xtrace
    ${C3D_ROOT}/c3d ${in_edt_map} -threshold ${distance} inf 1 0 -o ${out_effective_region_mask}
    set +o xtrace
  }

  run_corrField_registration () {
#    local hw_moving="26"
    local hw_moving="${hw}"
    local hw_fixed="6"
    local edt_moving=${preprocess_folder}/moving_edt.nii.gz
    local edt_fixed=${preprocess_folder}/fixed_edt.nii.gz
    local effective_moving=${output_folder}/moving_mask_effective.nii.gz
    local effective_fixed=${output_folder}/fixed_mask_effective.nii.gz
    local bounary_mask=${output_folder}/boundary_mask.nii.gz

    get_effective_region ${edt_moving} ${hw_moving} ${effective_moving}
    get_effective_region ${edt_fixed} ${hw_fixed} ${effective_fixed}

    echo ""
    echo "1. Get the effective region mask."
    local effective_mask=${output_folder}/effective_mask.nii.gz
    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_boundary_mask.py \
      --ref ${mask} \
      --dist ${hw_moving} \
      --out-mask ${bounary_mask}
    ${C3D_ROOT}/c3d ${mask} ${effective_moving} ${effective_fixed} ${bounary_mask}\
      -multiply -multiply -multiply -o ${effective_mask}
    set +o xtrace

    echo ""
    echo "2. Registration using the effective region mask."
    set -o xtrace
#    ${corrField_ROOT}/corrField -L 10x5 -a 1 \
#      -F ${preprocess_folder}/fixed_no_nan.nii.gz \
#      -M ${preprocess_folder}/moving_no_nan.nii.gz \
#      -m ${effective_mask} \
#      -O ${output_folder}/warp.dat
    ${corrField_ROOT}/corrField ${corrField_opt} \
      -F ${preprocess_folder}/fixed_no_nan.nii.gz \
      -M ${preprocess_folder}/moving_no_nan.nii.gz \
      -m ${effective_mask} \
      -O ${output_folder}/warp.dat

    ${corrField_ROOT}/convertWarpNiftyreg \
      -R ${mask} \
      -O ${output_folder}/warp.dat \
      -T ${output_folder}/trans.nii.gz

    ${NIFYREG_ROOT}/reg_resample \
      -ref ${mask} \
      -flo ${root_folder}/moving.nii.gz \
      -trans ${output_folder}/trans.nii.gz \
      -res ${output_folder}/warp.nii.gz
    set +o xtrace

    echo ""
    echo "4. Analyse the Jacobian map"
    ${NIFYREG_ROOT}/reg_jacobian \
      -trans ${output_folder}/trans.nii.gz \
      -ref ${mask} \
      -jac ${output_folder}/jac.nii.gz
    ${C3D_ROOT}/c3d ${output_folder}/jac.nii.gz \
      -threshold -inf 0 1 0 -o ${output_folder}/neg_jac_map.nii.gz
    ${C3D_ROOT}/c3d \
      -verbose ${output_folder}/neg_jac_map.nii.gz ${effective_mask} -overlap 1
  }

  echo ""
  echo "Run registration"
  run_corrField_registration
}

${RUN_CMD}
