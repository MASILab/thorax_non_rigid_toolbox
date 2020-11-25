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
  local OUTPUT_LOW_RES_3_FOLDER=${scan_root_folder}/output_low_res3
  local OUTPUT_HIGH_RES_FOLDER=${scan_root_folder}/output_high_res
  local OUTPUT_JAC_FOLDER=${scan_root_folder}/jac
  set -o xtrace
  mkdir -p ${OUTPUT_LOW_RES_FOLDER}
  mkdir -p ${OUTPUT_LOW_RES_2_FOLDER}
  mkdir -p ${OUTPUT_LOW_RES_3_FOLDER}
  mkdir -p ${OUTPUT_HIGH_RES_FOLDER}
  mkdir -p ${OUTPUT_JAC_FOLDER}
  set +o xtrace

  local FINAL_FOLDER=${OUTPUT_HIGH_RES_FOLDER}

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

    # 3. One additional low res step to make the search radius increase gradually.
    run_low_res_3 () {
      set -o xtrace
      ln -sf ${OUTPUT_LOW_RES_2_FOLDER}/mask.nii.gz ${OUTPUT_LOW_RES_3_FOLDER}/mask.nii.gz
      ln -sf ${OUTPUT_LOW_RES_2_FOLDER}/output/warp.nii.gz ${OUTPUT_LOW_RES_3_FOLDER}/moving.nii.gz
      set +o xtrace
      run_registration_pipeline_res ${OUTPUT_LOW_RES_3_FOLDER} "${corrField_config_step3}" "${effective_etch_step3}"
    }

    run_high_res () {
      set -o xtrace
      ln -sf ${REF_MASK_IMG} ${OUTPUT_HIGH_RES_FOLDER}/mask.nii.gz

      ${NIFYREG_ROOT}/reg_transform \
        -comp \
        ${OUTPUT_LOW_RES_FOLDER}/output/trans.nii.gz \
        ${OUTPUT_LOW_RES_2_FOLDER}/output/trans.nii.gz \
        ${OUTPUT_JAC_FOLDER}/trans_combine_1_2.nii.gz

      ${NIFYREG_ROOT}/reg_transform \
        -comp \
        ${OUTPUT_JAC_FOLDER}/trans_combine_1_2.nii.gz \
        ${OUTPUT_LOW_RES_3_FOLDER}/output/trans.nii.gz \
        ${OUTPUT_JAC_FOLDER}/trans_combine_low_res.nii.gz

      ${NIFYREG_ROOT}/reg_resample -inter 3 -pad NaN \
        -ref ${REF_MASK_IMG} \
        -flo ${MOVING_IMG} \
        -trans ${OUTPUT_JAC_FOLDER}/trans_combine_low_res.nii.gz \
        -res ${OUTPUT_HIGH_RES_FOLDER}/moving.nii.gz
      set +o xtrace
      run_registration_pipeline_res ${OUTPUT_HIGH_RES_FOLDER} "${corrField_config_step4}" "${effective_etch_step4}"
    }

    run_combined_jacobian_analysis () {
      set -o xtrace
      ${NIFYREG_ROOT}/reg_transform \
        -comp \
        ${OUTPUT_JAC_FOLDER}/trans_combine_low_res.nii.gz \
        ${OUTPUT_HIGH_RES_FOLDER}/output/trans.nii.gz \
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
        ${FINAL_FOLDER}/output/effective_mask.nii.gz \
        -overlap 1
      set +o xtrace

      set -o xtrace
      cp ${OUTPUT_JAC_FOLDER}/jac.nii.gz \
        ${OUTPUT_JAC_DET_FOLDER}/${scan_name}
      set +o xtrace
    }

    run_low_res_1
    run_low_res_2
    run_low_res_3
    run_high_res
    run_combined_jacobian_analysis

    mkdir -p ${OUTPUT_INTERP_FOLDER}/ori
    mkdir -p ${OUTPUT_INTERP_FOLDER}/trans
    set -o xtrace
    cp ${FINAL_FOLDER}/output/warp.nii.gz ${OUTPUT_INTERP_FOLDER}/ori/${scan_name}
    cp ${OUTPUT_LOW_RES_FOLDER}/output/warp.dat ${OUTPUT_INTERP_FOLDER}/trans/${scan_name}.low_res_1.dat
    cp ${OUTPUT_LOW_RES_2_FOLDER}/output/warp.dat ${OUTPUT_INTERP_FOLDER}/trans/${scan_name}.low_res_2.dat
    cp ${OUTPUT_LOW_RES_3_FOLDER}/output/warp.dat ${OUTPUT_INTERP_FOLDER}/trans/${scan_name}.low_res_3.dat
    cp ${OUTPUT_HIGH_RES_FOLDER}/output/warp.dat ${OUTPUT_INTERP_FOLDER}/trans/${scan_name}.high_res.dat
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
        --val -1000 \
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

recreate_trans_field () {
    local scan_name="$1"
    local scan_name_no_ext="${scan_name%.*}"

    local REF_MASK_IMG=${REFERENCE_FOLDER}/valid_region_mask.nii.gz

    local scan_root_folder=${OUTPUT_ROOT_FOLDER}/${scan_name_no_ext}
    local OUTPUT_JAC_FOLDER=${scan_root_folder}/jac
    local OUTPUT_HIGH_RES_FOLDER=${scan_root_folder}/output_high_res
    local low_res_combined_trans=${OUTPUT_JAC_FOLDER}/trans_combine_low_res.nii.gz
    local high_res_trans=${OUTPUT_HIGH_RES_FOLDER}/output/trans.nii.gz

    mkdir -p ${OUTPUT_JAC_FOLDER}
    mkdir -p ${OUTPUT_HIGH_RES_FOLDER}

    local trans_folder=${OUTPUT_INTERP_FOLDER}/trans

    local trans_low_res_1=${trans_folder}/${scan_name}.low_res_1.dat
    local trans_low_res_2=${trans_folder}/${scan_name}.low_res_2.dat
    local trans_low_res_3=${trans_folder}/${scan_name}.low_res_3.dat
    local trans_high_res=${trans_folder}/${scan_name}.high_res.dat

    set -o xtrace
    # Create low res mask
    low_res_mask=${OUTPUT_JAC_FOLDER}/low_res_mask.nii.gz
    ${C3D_ROOT}/c3d -int 0 \
        ${REF_MASK_IMG} -resample-mm 2x2x2mm \
        -o ${low_res_mask}

    # Low res 1
    ${corrField_ROOT}/convertWarpNiftyreg \
        -R ${low_res_mask} \
        -O ${trans_low_res_1} \
        -T ${OUTPUT_JAC_FOLDER}/trans_low_res_1.nii.gz

    # Low res 2
    ${corrField_ROOT}/convertWarpNiftyreg \
        -R ${low_res_mask} \
        -O ${trans_low_res_2} \
        -T ${OUTPUT_JAC_FOLDER}/trans_low_res_2.nii.gz

    # Low res 3
    ${corrField_ROOT}/convertWarpNiftyreg \
        -R ${low_res_mask} \
        -O ${trans_low_res_3} \
        -T ${OUTPUT_JAC_FOLDER}/trans_low_res_3.nii.gz

    # High res
#    ${corrField_ROOT}/convertWarpNiftyreg \
#        -R ${REF_MASK_IMG} \
#        -O ${trans_high_res} \
#        -T ${OUTPUT_JAC_FOLDER}/trans_high_res.nii.gz

    # Combine fields
    ${NIFYREG_ROOT}/reg_transform \
        -comp \
        ${OUTPUT_JAC_FOLDER}/trans_low_res_1.nii.gz \
        ${OUTPUT_JAC_FOLDER}/trans_low_res_2.nii.gz \
        ${OUTPUT_JAC_FOLDER}/trans_combine_1_2.nii.gz

    ${NIFYREG_ROOT}/reg_transform \
        -comp \
        ${OUTPUT_JAC_FOLDER}/trans_combine_1_2.nii.gz \
        ${OUTPUT_JAC_FOLDER}/trans_low_res_3.nii.gz \
        ${OUTPUT_JAC_FOLDER}/trans_combine_low_res.nii.gz

    # Combine with affine matrix
    local omat_txt=${MASK_FOLDER}/../omat/"${scan_name_no_ext%.*}".txt
    ${NIFYREG_ROOT}/reg_transform \
        -comp \
        ${OUTPUT_JAC_FOLDER}/trans_combine_low_res.nii.gz \
        ${omat_txt} \
        ${OUTPUT_JAC_FOLDER}/trans_combine_low_res_add_affine.nii.gz \
        -ref \
        ${low_res_mask}

    # Get the Jacobian matrix
    ${NIFYREG_ROOT}/reg_jacobian \
        -trans ${OUTPUT_JAC_FOLDER}/trans_combine_low_res_add_affine.nii.gz \
        -ref ${low_res_mask} \
        -jacM ${OUTPUT_JAC_FOLDER}/trans_combine_low_res_add_affine_jacM.nii.gz

    ${NIFYREG_ROOT}/reg_jacobian \
        -trans ${OUTPUT_JAC_FOLDER}/trans_combine_low_res_add_affine.nii.gz \
        -ref ${low_res_mask} \
        -jacL ${OUTPUT_JAC_FOLDER}/trans_combine_low_res_add_affine_jacL.nii.gz

    # Get the 9 matrix elements
    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_jacobian_elements_all.py \
        --in-trans-img ${OUTPUT_JAC_FOLDER}/trans_combine_low_res_add_affine_jacM.nii.gz \
        --in-ref-img ${low_res_mask} \
        --out-jac-elem-prefix ${OUTPUT_JAC_FOLDER}/jac_elem \
        --c3d-path ${C3D_ROOT}/c3d

    mkdir -p ${OUTPUT_INTERP_FOLDER}/jac_elem
    mkdir -p ${OUTPUT_INTERP_FOLDER}/jac_elem_clip_95
    mkdir -p ${OUTPUT_INTERP_FOLDER}/jacL_add_affine
    scan_name_no_ext_no_ext="${scan_name_no_ext%.*}"

    for (( idx_elem=0; idx_elem<9; idx_elem++ ))
    do
        cp ${OUTPUT_JAC_FOLDER}/jac_elem_${idx_elem}_raw.nii.gz ${OUTPUT_INTERP_FOLDER}/jac_elem/${scan_name_no_ext_no_ext}_${idx_elem}.nii.gz
        cp ${OUTPUT_JAC_FOLDER}/jac_elem_${idx_elem}_clip_95.nii.gz ${OUTPUT_INTERP_FOLDER}/jac_elem_clip_95/${scan_name_no_ext_no_ext}_${idx_elem}.nii.gz
    done
    cp ${OUTPUT_JAC_FOLDER}/trans_combine_low_res_add_affine_jacL.nii.gz ${OUTPUT_INTERP_FOLDER}/jacL_add_affine/${scan_name}

#    ${NIFYREG_ROOT}/reg_jacobian \
#        -trans ${OUTPUT_JAC_FOLDER}/trans_combine_low_res.nii.gz \
#        -ref ${low_res_mask} \
#        -jacM ${OUTPUT_JAC_FOLDER}/trans_combine_low_res_jacM.nii.gz
#
#    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_jacobian_deformable_index.py \
#        --in-trans-img ${OUTPUT_JAC_FOLDER}/trans_combine_low_res_jacM.nii.gz \
#        --in-ref-img ${low_res_mask} \
#        --out-d-idx-img ${OUTPUT_JAC_FOLDER}/low_res_d_index.nii.gz

#    mkdir -p ${OUTPUT_INTERP_FOLDER}/d_index
#    cp ${OUTPUT_JAC_FOLDER}/low_res_d_index.nii.gz ${OUTPUT_INTERP_FOLDER}/d_index/${scan_name}

#    ${NIFYREG_ROOT}/reg_transform \
#        -comp \
#        ${OUTPUT_JAC_FOLDER}/trans_combine_low_res.nii.gz \
#        ${OUTPUT_JAC_FOLDER}/trans_high_res.nii.gz \
#        ${OUTPUT_JAC_FOLDER}/trans_combine.nii.gz

    set +o xtrace
}

run_interp_scan () {
  local scan_name="$1"
  local scan_name_no_ext="${scan_name%.*}"

  local REF_MASK_IMG=${REFERENCE_FOLDER}/valid_region_mask.nii.gz

  local scan_root_folder=${OUTPUT_ROOT_FOLDER}/${scan_name_no_ext}
  local OUTPUT_JAC_FOLDER=${scan_root_folder}/jac
  local low_res_combined_trans=${OUTPUT_JAC_FOLDER}/trans_combine_low_res.nii.gz
  local high_res_trans=${OUTPUT_JAC_FOLDER}/trans_high_res.nii.gz

  run_interp_scan_flag () {
    local mask_flag="$1"
    local interp_order="$2"
    local pad_value="$3"

    local in_mask=${MASK_FOLDER}/${mask_flag}/${scan_name}
    local out_mask_folder=${OUTPUT_INTERP_FOLDER}/${mask_flag}
    mkdir -p ${out_mask_folder}
    local out_mask=${out_mask_folder}/${scan_name}

#    set -o xtrace
#    ${NIFYREG_ROOT}/reg_resample \
#      -inter ${interp_order} -pad ${pad_value} \
#      -ref ${REF_MASK_IMG} \
#      -flo ${in_mask} \
#      -trans ${low_res_combined_trans} \
#      -res ${out_mask}_low_res_trans.nii.gz

    set -o xtrace
    low_res_mask=${OUTPUT_JAC_FOLDER}/low_res_mask.nii.gz
    ${NIFYREG_ROOT}/reg_resample \
      -inter ${interp_order} -pad ${pad_value} \
      -ref ${low_res_mask} \
      -flo ${in_mask} \
      -res ${in_mask}_low_res.nii.gz

    ${NIFYREG_ROOT}/reg_resample \
      -inter ${interp_order} -pad ${pad_value} \
      -ref ${low_res_mask} \
      -flo ${in_mask}_low_res.nii.gz \
      -trans ${low_res_combined_trans} \
      -res ${out_mask}

#    ${NIFYREG_ROOT}/reg_resample \
#      -inter 0 -pad 0 \
#      -ref ${REF_MASK_IMG} \
#      -flo ${out_mask}_low_res_trans.nii.gz \
#      -trans ${high_res_trans} \
#      -res ${out_mask}

#    rm ${out_mask}_low_res_trans.nii.gz
    set +o xtrace
  }

  get_effective_region () {
    local out_mask_folder=${OUTPUT_INTERP_FOLDER}/effective_region
    local final_effective_region_mask=${OUTPUT_HIGH_RES_FOLDER}/output/effective_mask.nii.gz

    set -o xtrace
    mkdir -p ${out_mask_folder}
    cp ${final_effective_region_mask} ${out_mask_folder}/${scan_name}
    set +o xtrace
  }

#  run_interp_scan_flag lung_mask
#  run_interp_scan_flag body_mask
#  get_effective_region
#    run_interp_scan_flag cam_heatmap 3 0
}

rm_temp_files () {
  local scan_name="$1"
  local scan_name_no_ext="${scan_name%.*}"
  local scan_root_folder=${OUTPUT_ROOT_FOLDER}/${scan_name_no_ext}

  set -o xtrace
  rm -rf ${scan_root_folder}
  set +o xtrace
}