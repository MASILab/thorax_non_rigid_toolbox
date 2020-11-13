
run_process_one_scan () {
  local scan_path=$1
  local scan_name=$(basename -- "$scan_path")
  local scan_name_no_ext="${scan_name%.*}"

  local MOVING_IMG=${scan_path}

  local scan_root_folder=${OUTPUT_ROOT_FOLDER}/${scan_name_no_ext}
  mkdir -p ${scan_root_folder}

  local OUTPUT_LOW_RES_FOLDER=${scan_root_folder}/output_low_res
  local OUTPUT_LOW_RES_2_FOLDER=${scan_root_folder}/output_low_res2
  local OUTPUT_HIGH_RES_FOLDER=${scan_root_folder}/output_high_res
  local OUTPUT_HIGH_RES_2_FOLDER=${scan_root_folder}/output_high_res2
  local OUTPUT_JAC_FOLDER=${scan_root_folder}/jac
  mkdir -p ${OUTPUT_LOW_RES_FOLDER}
  mkdir -p ${OUTPUT_LOW_RES_2_FOLDER}
  mkdir -p ${OUTPUT_HIGH_RES_FOLDER}
  mkdir -p ${OUTPUT_HIGH_RES_2_FOLDER}
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
      run_registration_pipeline_res ${OUTPUT_HIGH_RES_FOLDER} "${corrField_config_step3}" "${effective_etch_step3}"
    }

    # 4. Run high res with updated mask.
    run_high_res_2 () {
      set -o xtrace
      ln -sf ${MASK_IMG} ${OUTPUT_HIGH_RES_2_FOLDER}/mask.nii.gz
      ln -sf ${OUTPUT_HIGH_RES_FOLDER}/output/warp.nii.gz ${OUTPUT_HIGH_RES_2_FOLDER}/moving.nii.gz
      set +o xtrace
      run_registration_pipeline_res ${OUTPUT_HIGH_RES_2_FOLDER} "${corrField_config_step4}" "${effective_etch_step4}"
    }

    run_combined_jacobian_analysis () {
      set -o xtrace
      ${NIFYREG_ROOT}/reg_transform \
        -comp \
        ${OUTPUT_HIGH_RES_FOLDER}/trans_combine.nii.gz \
        ${OUTPUT_HIGH_RES_FOLDER}/output/trans.nii.gz \
        ${OUTPUT_JAC_FOLDER}/trans_combine_1.nii.gz

      ${NIFYREG_ROOT}/reg_transform \
        -comp \
        ${OUTPUT_JAC_FOLDER}/trans_combine_1.nii.gz \
        ${OUTPUT_HIGH_RES_2_FOLDER}/output/trans.nii.gz \
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

      set -o xtrace
      cp ${OUTPUT_JAC_FOLDER}/jac_full_res.nii.gz \
        ${OUTPUT_JAC_DET_FOLDER}/${scan_name}
      set +o xtrace
    }

    run_low_res_1
    run_low_res_2
    run_high_res
    run_high_res_2
    run_combined_jacobian_analysis

    mkdir -p ${OUTPUT_INTERP_FOLDER}/ori
    set -o xtrace
    cp ${OUTPUT_HIGH_RES_2_FOLDER}/output/warp.nii.gz ${OUTPUT_INTERP_FOLDER}/ori/${scan_name}
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
  local scan_path=$1
  local scan_name=$(basename -- "$scan_path")
  local scan_name_no_ext="${scan_name%.*}"

  local scan_root_folder=${OUTPUT_ROOT_FOLDER}/${scan_name_no_ext}
  local OUTPUT_HIGH_RES_FOLDER=${scan_root_folder}/output_high_res
  local OUTPUT_HIGH_RES_2_FOLDER=${scan_root_folder}/output_high_res2
  local scan_trans_low_res_combine=${OUTPUT_HIGH_RES_FOLDER}/trans_combine.nii.gz
  local scan_trans_high_res=${OUTPUT_HIGH_RES_FOLDER}/output/trans.nii.gz
  local scan_trans_high_res2=${OUTPUT_HIGH_RES_2_FOLDER}/output/trans.nii.gz

  run_interp_scan_flag () {
    local mask_flag="$1"

    local in_mask=${MASK_FOLDER}/${mask_flag}/${scan_name}
    local out_mask_folder=${OUTPUT_INTERP_FOLDER}/${mask_flag}
    mkdir -p ${out_mask_folder}
    local out_mask=${out_mask_folder}/${scan_name}

    set -o xtrace
    ${NIFYREG_ROOT}/reg_resample \
      -inter 0 -pad 0 \
      -ref ${MASK_IMG} \
      -flo ${in_mask} \
      -trans ${scan_trans_low_res_combine} \
      -res ${out_mask}_temp_1.nii.gz

    ${NIFYREG_ROOT}/reg_resample \
      -inter 0 -pad 0 \
      -ref ${MASK_IMG} \
      -flo ${out_mask}_temp_1.nii.gz \
      -trans ${scan_trans_high_res} \
      -res ${out_mask}_temp_2.nii.gz

    ${NIFYREG_ROOT}/reg_resample \
      -inter 0 -pad 0 \
      -ref ${MASK_IMG} \
      -flo ${out_mask}_temp_2.nii.gz \
      -trans ${scan_trans_high_res2} \
      -res ${out_mask}
    rm ${out_mask}_temp_1.nii.gz
    rm ${out_mask}_temp_2.nii.gz
    set +o xtrace
  }

  run_interp_scan_flag lung_mask
  run_interp_scan_flag body_mask
}

run_moving_scan_folder () {
  mapfile -t cmds < ${FILE_LIST}
  local num_scans=$(cat ${FILE_LIST} | wc -l )

  echo "Number of scans ${num_scans}"
  for file_id in $(seq 0 $((${num_scans}-1)))
  do
    local scan_name=${cmds[$file_id]}
    local scan_path=${MOVING_FOLDER}/${scan_name}

    echo ""
    echo "Process scan ${scan_name} (${file_id}/${num_scans})"
    run_process_one_scan ${scan_path} &
  done
  wait
}


run_scan_list_batch () {
  local size_batch="$1"

  mapfile -t cmds < ${FILE_LIST}
  local num_scans=$(cat ${FILE_LIST} | wc -l )
  cat ${FILE_LIST}
  echo ${num_scans}

  local num_batch=$((${num_scans}/${size_batch}))

  for batch_id in $( seq "0" "${num_batch}" )
  do
    SEQ_LOW=$((${batch_id}*${size_batch}))
    SEQ_UP=$(((${batch_id}+1)*${size_batch}-1))

    if [ "${SEQ_UP}" -gt "$((${num_scans}-1))" ]
    then
      SEQ_UP="$((${num_scans}-1))"
    fi

    for scan_id in $(seq ${SEQ_LOW} ${SEQ_UP})
    do
      local scan_name=${cmds[$scan_id]}
      local scan_path=${MOVING_FOLDER}/${scan_name}

      echo ""
      echo "Process scan ${scan_name} (${scan_id}/${num_scans})"
      run_pipeline_combined () {
        run_process_one_scan ${scan_path}
        run_interp_scan ${scan_path}
      }
      run_pipeline_combined &
#      run_pipeline_combined
    done
    wait
  done
}
