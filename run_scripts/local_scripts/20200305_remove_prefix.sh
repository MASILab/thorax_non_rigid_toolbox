#!/bin/bash

###################### Change Log ################
# 3/5/2020 - Kaiwen
##################################################

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Add prefix for atlas"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}

DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200304_10_atlas_affine

atlas_folder=${DATA_ROOT}/multi_atlas/atlas
atlas_thr_folder=${DATA_ROOT}/multi_atlas/atlas_thr
label_refine_folder=${DATA_ROOT}/multi_atlas/label_refine

remove_prefix_scan_path () {
  local scan_path=$1
  local count="$2"

  local scan_base_name="$(basename -- ${scan_path})"
  local dir_path="$( dirname -- ${scan_path} )"

  local prefix="atlas"
  local new_scan_name=${scan_base_name#"$prefix"?_}
  local new_scan_path=${dir_path}/${new_scan_name}

  set -o xtrace
  mv ${scan_path} ${new_scan_path}
  set +o xtrace
}

remove_prefix_folder () {
  local folder_path=$1

  count="0"
  for file_path in "${folder_path}"/*.nii.gz
  do
    count=$((${count} + 1))
    remove_prefix_scan_path ${file_path} ${count}
  done
}

remove_prefix_folder ${atlas_folder}
remove_prefix_folder ${atlas_thr_folder}
remove_prefix_folder ${label_refine_folder}
