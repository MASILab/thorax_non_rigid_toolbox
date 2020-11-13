get_metric_table () {
  local dice_data_root=${ANALYSIS_DICE_ROOT}
  local surface_data_root=${ANSLYSIS_SURFACE_ROOT}
  local item_list=${ANALYSIS_TEST_LIST}
  local out_csv_folder=${METRIC_TABLE_FOLDER}

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_metric_statics_table.py \
    --dice-data-root ${dice_data_root} \
    --surface-data-root ${surface_data_root} \
    --item-list ${item_list} \
    --out-csv-folder ${out_csv_folder}
  set +o xtrace
}

get_dice_table () {
  local dice_data_root=${ANALYSIS_DICE_ROOT}
  local item_list=${ANALYSIS_TEST_LIST}
  local out_csv_folder=${METRIC_TABLE_FOLDER}/dice_only
  mkdir -p ${out_csv_folder}

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_metric_statics_table_dice_only.py \
    --dice-data-root ${dice_data_root} \
    --item-list ${item_list} \
    --out-csv-folder ${out_csv_folder}
  set +o xtrace
}