get_surface_deeds () {
  local mask_flag="$1"

  local in_folder=${NON_RIGID_INTERP_ROOT}/${mask_flag}
  local gt_mask=${REFERENCE_ROOT}/${mask_flag}.nii.gz
  local out_csv_folder=${ANSLYSIS_SURFACE_ROOT}/deeds
  mkdir -p ${out_csv_folder}
  local out_csv=${out_csv_folder}/${mask_flag}.csv
  local effective_mask_folder=${DICE_VALID_REGION_MASK_FOLDER}/deeds

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_surface_distance_statics.py \
    --in-folder ${in_folder} \
    --in-effective-mask-folder ${effective_mask_folder} \
    --file-list-txt ${DATA_LIST} \
    --gt-mask ${gt_mask} \
    --out-csv ${out_csv}
  set +o xtrace
}

get_surface_corrField () {
  local test_flag="$1"
  local mask_flag="$2"

  local in_folder=${CORRFIELD_ROOT}/${test_flag}/interp/${mask_flag}
  local effective_mask_folder=${DICE_VALID_REGION_MASK_FOLDER}/${test_flag}
  local gt_mask=${REFERENCE_ROOT}/${mask_flag}.nii.gz
  local out_folder=${ANSLYSIS_SURFACE_ROOT}/${test_flag}
  mkdir -p ${out_folder}
  local out_csv=${out_folder}/${mask_flag}.csv

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_surface_distance_statics.py \
    --in-folder ${in_folder} \
    --in-effective-mask-folder ${effective_mask_folder} \
    --file-list-txt ${DATA_LIST} \
    --gt-mask ${gt_mask} \
    --out-csv ${out_csv}
  set +o xtrace
}

get_surface_corrField_test () {
  local test_flag="$1"

  get_surface_corrField ${test_flag} lung_mask
  get_surface_corrField ${test_flag} body_mask
}

get_surface_dist () {
  get_surface_deeds lung_mask
  get_surface_deeds body_mask

  get_surface_corrField_test corrField_naive
  get_surface_corrField_test corrField_multistep
}
