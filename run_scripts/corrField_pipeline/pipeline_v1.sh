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
MASK_2MM_IMG=${TEST_DATA_FOLDER}/roi_mask_2mm.nii.gz
IDENTITY_MAT=${TEST_DATA_FOLDER}/idendity_matrix.txt

OUTPUT_LOW_RES_FOLDER=${PROJ_ROOT}/output_low_res
OUTPUT_FULL_RES_FOLDER=${PROJ_ROOT}/output_full_res
OUTPUT_PREPROCESS=${OUTPUT_LOW_RES_FOLDER}/reprocess
OUTPUT_REGISTRATION=${OUTPUT_LOW_RES_FOLDER}/registration

mkdir -p ${OUTPUT_LOW_RES_FOLDER}



mkdir -p ${OUTPUT_PREPROCESS}
mkdir -p ${OUTPUT_REGISTRATION}

run_preprocess_scan () {
  # 1. Downsample ori to 2x2x2mm for both fixed and moving
  # 2. Extract non-nan-region mask for both fixed and moving
  # 3. Replace nan.
  # 4. Get the signed distance transform. Voxels inside the region are with negative value.
  local in_scan=$1
  local in_scan_basename=$(basename -- ${in_scan})

  local out_resampled=${OUTPUT_PREPROCESS}/${in_scan_basename}
  local out_valid_region_mask=${OUTPUT_PREPROCESS}/${in_scan_basename}_valid_region.nii.gz
  local out_signed_distance=${OUTPUT_PREPROCESS}/${in_scan_basename}_sdt.nii.gz

  set -o xtrace
#  ${C3D_ROOT}/c3d ${in_scan} -resample-mm 2x2x2mm -o ${out_resampled}
  ${NIFYREG_ROOT}/reg_resample -inter 3 -pad NaN -ref ${MASK_2MM_IMG} -flo ${in_scan} -trans ${IDENTITY_MAT} -res ${out_resampled}
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_non_nan_region.py \
    --ori ${out_resampled} \
    --out-mask ${out_valid_region_mask}
  ${PYTHON_ENV} ${SRC_ROOT}/tools/replace_nan.py \
    --val 0 \
    --in_image ${out_resampled} \
    --out_image ${out_resampled}_no_nan.nii.gz
  mv ${out_resampled}_no_nan.nii.gz ${out_resampled}
  ${C3D_ROOT}/c3d ${out_valid_region_mask} -sdt -o ${out_signed_distance}
  set +o xtrace
}

run_preprocess () {
  run_preprocess_scan ${MOVING_IMG}
  run_preprocess_scan ${FIXED_IMG}
}



run_corrField_pipeline () {
  local hw_moving="26"
  local hw_fixed="6"
  local sdt_moving=${OUTPUT_PREPROCESS}/moving.nii.gz_sdt.nii.gz
  local sdt_fixed=${OUTPUT_PREPROCESS}/fixed.nii.gz_sdt.nii.gz
  local effective_moving=${OUTPUT_REGISTRATION}/moving_mask_effective.nii.gz
  local effective_fixed=${OUTPUT_REGISTRATION}/fixed_mask_effective.nii.gz
  local roi_mask=${OUTPUT_REGISTRATION}/roi_mask.nii.gz

  get_effective_region ${sdt_moving} ${hw_moving} ${effective_moving}
  get_effective_region ${sdt_fixed} ${hw_fixed} ${effective_fixed}

  echo ""
  echo "1. Get the effective region mask."
  local effective_mask=${OUTPUT_REGISTRATION}/effective_mask.nii.gz
  set -o xtrace
  ${C3D_ROOT}/c3d -int 0 ${MASK_IMG} -resample-mm 2x2x2mm -o ${roi_mask}
  ${C3D_ROOT}/c3d ${roi_mask} ${effective_moving} ${effective_fixed} -multiply -multiply -o ${effective_mask}
  set +o xtrace

  echo ""
  echo "2. Registration using the effective region mask."
  set -o xtrace
  ${corrField_ROOT}/corrField -L 10x5 -a 1 \
    -F ${OUTPUT_PREPROCESS}/fixed.nii.gz \
    -M ${OUTPUT_PREPROCESS}/moving.nii.gz \
    -m ${effective_mask} \
    -O ${OUTPUT_REGISTRATION}/warp.dat
  # ${corrField_ROOT}/applyCorrField -M ${MOVING_IMG} -O ${OUTPUT_FOLDER}/warp.dat -W ${OUTPUT_FOLDER}/warp.nii.gz
  ${corrField_ROOT}/convertWarpNiftyreg \
    -R ${OUTPUT_PREPROCESS}/fixed.nii.gz \
    -O ${OUTPUT_REGISTRATION}/warp.dat \
    -T ${OUTPUT_REGISTRATION}/trans.nii.gz
  ${NIFYREG_ROOT}/reg_resample \
    -ref ${OUTPUT_PREPROCESS}/fixed.nii.gz \
    -flo ${OUTPUT_PREPROCESS}/moving.nii.gz \
    -trans ${OUTPUT_REGISTRATION}/trans.nii.gz \
    -res ${OUTPUT_REGISTRATION}/warp.nii.gz
  set +o xtrace

  echo ""
  echo "3. Interpolate to full resolution."
  set -o xtrace
  ${NIFYREG_ROOT}/reg_resample \
    -ref ${FIXED_IMG} \
    -flo ${MOVING_IMG} \
    -trans ${OUTPUT_REGISTRATION}/trans.nii.gz \
    -res ${OUTPUT_REGISTRATION}/warp_full_res.nii.gz
  set +o xtrace

  echo ""
  echo "4. Analyse the Jacobian map"
  ${NIFYREG_ROOT}/reg_jacobian \
    -trans ${OUTPUT_REGISTRATION}/trans.nii.gz \
    -ref ${OUTPUT_PREPROCESS}/fixed.nii.gz \
    -jac ${OUTPUT_REGISTRATION}/jac.nii.gz
  ${C3D_ROOT}/c3d \
    ${OUTPUT_REGISTRATION}/jac.nii.gz -threshold -inf 0 1 0 -o ${OUTPUT_REGISTRATION}/neg_jac_map.nii.gz
  ${C3D_ROOT}/c3d -verbose ${OUTPUT_REGISTRATION}/neg_jac_map.nii.gz ${effective_mask} -overlap 1
}


${RUN_CMD}
