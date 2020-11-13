get_dice_deeds () {
  local mask_flag="$1"

  local in_folder=${NON_RIGID_INTERP_ROOT}/${mask_flag}
  local gt_mask=${REFERENCE_ROOT}/${mask_flag}.nii.gz
  local out_csv=${ANALYSIS_DICE_ROOT}/${mask_flag}.csv
  local effective_mask_folder=${DICE_VALID_REGION_MASK_FOLDER}/deeds

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_dice_statics.py \
    --in-folder ${in_folder} \
    --in-effective-mask-folder ${effective_mask_folder} \
    --file-list-txt ${DATA_LIST} \
    --gt-mask ${gt_mask} \
    --out-csv ${out_csv}
  set +o xtrace
}

get_dice_corrField () {
  local test_flag="$1"
  local mask_flag="$2"

  local in_folder=${CORRFIELD_ROOT}/${test_flag}/interp/${mask_flag}
  local effective_mask_folder=${DICE_VALID_REGION_MASK_FOLDER}/${test_flag}
  local gt_mask=${REFERENCE_ROOT}/${mask_flag}.nii.gz
  local out_folder=${ANALYSIS_DICE_ROOT}/${test_flag}
  mkdir -p ${out_folder}
  local out_csv=${out_folder}/${mask_flag}.csv

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_dice_statics.py \
    --in-folder ${in_folder} \
    --in-effective-mask-folder ${effective_mask_folder} \
    --file-list-txt ${DATA_LIST} \
    --gt-mask ${gt_mask} \
    --out-csv ${out_csv}
  set +o xtrace
}

get_dice () {
  local test_flag="$1"

  if [ "$test_flag" = deeds ]; then
    get_dice_deeds lung_mask
    get_dice_deeds body_mask
  else
    get_dice_corrField ${test_flag} lung_mask
    get_dice_corrField ${test_flag} body_mask
  fi
}

get_dice_box () {
  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_dice_statics_table.py \
    --dice-data-root ${ANALYSIS_DICE_ROOT} \
    --item-list ${ANALYSIS_TEST_LIST} \
    --out-fig-folder ${OUT_METRIC_BOX_FOLDER}
  set +o xtrace
}

get_effective_region_masks () {
  local test_flag="$1"

  local valid_region_mask_folder=${DICE_VALID_REGION_MASK_FOLDER}
  local in_ref_valid_mask=${CORRFIELD_ROOT}/data_shared/valid_mask_fixed.nii.gz

  get_effective_region_deeds () {
    local in_ori_folder=${NON_RIGID_INTERP_ROOT}/ori
    local out_folder=${valid_region_mask_folder}/deeds
    mkdir -p ${out_folder}

    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_dice_effective_region.py \
      --in-ori-folder ${in_ori_folder} \
      --file-list-txt ${DATA_LIST} \
      --in-ref-valid-mask ${in_ref_valid_mask} \
      --out-folder ${out_folder} \
      --etch-radius ${METRIC_ETCH_RADIUS}
    set +o xtrace
  }

  get_effective_region_corrField () {
    local test_flag="$1"

    local in_ori_folder=${CORRFIELD_ROOT}/${test_flag}/interp/ori
    local out_folder=${valid_region_mask_folder}/${test_flag}
    mkdir -p ${out_folder}

    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/get_dice_effective_region.py \
      --in-ori-folder ${in_ori_folder} \
      --file-list-txt ${DATA_LIST} \
      --in-ref-valid-mask ${in_ref_valid_mask} \
      --out-folder ${out_folder} \
      --etch-radius ${METRIC_ETCH_RADIUS}
    set +o xtrace
  }

  if [ "$test_flag" = deeds ]; then
    get_effective_region_deeds
  else
    get_effective_region_corrField ${test_flag}
  fi
}

run_dice_combined () {
  local num_test=$(cat ${ANALYSIS_TEST_LIST} | wc -l)
  mapfile -t cmds < ${ANALYSIS_TEST_LIST}

  for test_id in $( seq "0" $((${num_test} - 1)) )
  do
    local test_flag=${cmds[$test_id]}
    get_effective_region_masks ${test_flag}
    get_dice ${test_flag}
  done

  get_dice_box
}
