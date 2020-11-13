run_process_one_scan () {
  local scan_name="$1"
  local scan_name_no_ext="${scan_name%.*}"

  local MOVING_IMG=${MOVING_FOLDER}/${scan_name}
  local REF_MASK_IMG=${REFERENCE_FOLDER}/valid_region_mask.nii.gz

  local scan_root_folder=${OUTPUT_ROOT_FOLDER}/${scan_name_no_ext}
  set -o xtrace
  mkdir -p ${scan_root_folder}
  set +o xtrace

  local OUTPUT_LOW_RES_FOLDER=${scan_root_folder}/output_low_res
  local OUTPUT_LOW_RES_2_FOLDER=${scan_root_folder}/output_low_res2
  local OUTPUT_JAC_FOLDER=${scan_root_folder}/jac
  set -o xtrace
  mkdir -p ${OUTPUT_LOW_RES_FOLDER}
  mkdir -p ${OUTPUT_LOW_RES_2_FOLDER}
  mkdir -p ${OUTPUT_JAC_FOLDER}
  set +o xtrace

  run_registration_pipeline () {
    # 1. Run low resolution
    run_low_res_1 () {
      set -o xtrace
      ${C3D_ROOT}/c3d -int 0 \
        ${REF_MASK_IMG} -resample-mm 2x2x2mm \
        -o ${OUTPUT_LOW_RES_FOLDER}/mask.nii.gz
      ${NIFYREG_ROOT}/reg_resample -inter 3 -pad NaN \
        -ref ${OUTPUT_LOW_RES_FOLDER}/mask.nii.gz \
        -flo ${MOVING_IMG} \
        -trans ${IDENTITY_MAT} \
        -res ${OUTPUT_LOW_RES_FOLDER}/moving.nii.gz
      set +o xtrace
      run_registration_pipeline_res ${OUTPUT_LOW_RES_FOLDER} "${corrField_config_step1}" "${effective_etch_step1}"
    }

    # 2. Run with updated mask still with low resolution.
    run_low_res_2 () {
      set -o xtrace
      ln -sf ${OUTPUT_LOW_RES_FOLDER}/mask.nii.gz ${OUTPUT_LOW_RES_2_FOLDER}/mask.nii.gz
      ln -sf ${OUTPUT_LOW_RES_FOLDER}/output/warp.nii.gz ${OUTPUT_LOW_RES_2_FOLDER}/moving.nii.gz
      set +o xtrace
      run_registration_pipeline_res ${OUTPUT_LOW_RES_2_FOLDER} "${corrField_config_step2}" "${effective_etch_step2}"
    }

    run_combined_jacobian_analysis () {
      set -o xtrace
      ${NIFYREG_ROOT}/reg_transform \
        -comp \
        ${OUTPUT_LOW_RES_FOLDER}/output/trans.nii.gz \
        ${OUTPUT_LOW_RES_2_FOLDER}/output/trans.nii.gz \
        ${OUTPUT_JAC_FOLDER}/trans_combine.nii.gz

      ${NIFYREG_ROOT}/reg_jacobian \
        -trans ${OUTPUT_JAC_FOLDER}/trans_combine.nii.gz \
        -ref ${REF_MASK_IMG} \
        -jac ${OUTPUT_JAC_FOLDER}/jac.nii.gz

      ${C3D_ROOT}/c3d \
        ${OUTPUT_JAC_FOLDER}/jac.nii.gz \
        -threshold -inf 0 1 0 -o ${OUTPUT_JAC_FOLDER}/neg_jac_map.nii.gz

      ${C3D_ROOT}/c3d \
        -verbose \
        ${OUTPUT_JAC_FOLDER}/neg_jac_map.nii.gz \
        ${OUTPUT_LOW_RES_2_FOLDER}/output/effective_mask.nii.gz \
        -overlap 1
      set +o xtrace

      set -o xtrace
      cp ${OUTPUT_JAC_FOLDER}/jac.nii.gz \
        ${OUTPUT_JAC_DET_FOLDER}/${scan_name}
      set +o xtrace
    }

    run_low_res_1
    run_low_res_2
    run_combined_jacobian_analysis

    mkdir -p ${OUTPUT_INTERP_FOLDER}/ori
    set -o xtrace
    cp ${OUTPUT_LOW_RES_2_FOLDER}/output/warp.nii.gz ${OUTPUT_INTERP_FOLDER}/ori/${scan_name}
    set +o xtrace
  }

  run_registration_pipeline_res () {
    local root_folder=$1
    local corrField_opt="$2"
    local hw="$3"

    local mask=${root_folder}/mask.nii.gz

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
        -inter 3 -pad NaN \
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

  run_registration_pipeline
}

run_interp_scan () {
  local scan_name="$1"
  local scan_name_no_ext="${scan_name%.*}"

  local REF_MASK_IMG=${REFERENCE_FOLDER}/valid_region_mask.nii.gz

  local scan_root_folder=${OUTPUT_ROOT_FOLDER}/${scan_name_no_ext}
  local OUTPUT_LOW_RES_FOLDER=${scan_root_folder}/output_low_res
  local OUTPUT_LOW_RES_2_FOLDER=${scan_root_folder}/output_low_res2
  local low_res_1_trans=${OUTPUT_LOW_RES_FOLDER}/output/trans.nii.gz
  local low_res_2_trans=${OUTPUT_LOW_RES_2_FOLDER}/output/trans.nii.gz

  run_interp_scan_flag () {
    local mask_flag="$1"

    local in_mask=${MASK_FOLDER}/${mask_flag}/${scan_name}
    local out_mask_folder=${OUTPUT_INTERP_FOLDER}/${mask_flag}
    mkdir -p ${out_mask_folder}
    local out_mask=${out_mask_folder}/${scan_name}

    set -o xtrace
    ${NIFYREG_ROOT}/reg_resample \
      -inter 0 -pad 0 \
      -ref ${REF_MASK_IMG} \
      -flo ${in_mask} \
      -trans ${low_res_1_trans} \
      -res ${out_mask}_temp.nii.gz

    ${NIFYREG_ROOT}/reg_resample \
      -inter 0 -pad 0 \
      -ref ${REF_MASK_IMG} \
      -flo ${out_mask}_temp.nii.gz \
      -trans ${low_res_2_trans} \
      -res ${out_mask}
    rm ${out_mask}_temp.nii.gz
    set +o xtrace
  }

  get_effective_region () {
    local out_mask_folder=${OUTPUT_INTERP_FOLDER}/effective_region
    local final_effective_region_mask=${OUTPUT_LOW_RES_2_FOLDER}/output/effective_mask.nii.gz

    set -o xtrace
    mkdir -p ${out_mask_folder}
    cp ${final_effective_region_mask} ${out_mask_folder}/${scan_name}
    set +o xtrace
  }

  run_interp_scan_flag lung_mask
  run_interp_scan_flag body_mask
  get_effective_region
}

rm_temp_files () {
  local scan_name="$1"
  local scan_name_no_ext="${scan_name%.*}"
  local scan_root_folder=${OUTPUT_ROOT_FOLDER}/${scan_name_no_ext}

  set -o xtrace
  rm -rf ${scan_root_folder}
  set +o xtrace
}