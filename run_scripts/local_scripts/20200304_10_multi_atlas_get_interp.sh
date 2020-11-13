#!/bin/bash

###################### Change Log ################
# 3/4/2020 - Kaiwen
# Write out affine pipeline configuration files for subject to subject reg.
##################################################

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Generate sagittal slices"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}
source ${SRC_ROOT}/tools/reg_preprocess_functions.sh

DATA_ROOT=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/label_propagation/20200304_10_atlas_affine

affine_root=${DATA_ROOT}/affine/scans
flo_img_name=00000301time20160622.nii.gz
flo_img_name_no_ext=00000301time20160622
out_interp_folder=${DATA_ROOT}/affine/output/${flo_img_name_no_ext}/interp

mkdir -p ${out_interp_folder}

cp_interp_img () {
  local scan_name=$1

  echo "Apply z mask ${scan_name}"

  local in_img=${affine_root}/${scan_name}/interp/ori/${flo_img_name}
  local out_img=${out_interp_folder}/${scan_name}.nii.gz

  set -o xtrace
  cp ${in_img} ${out_img}
  set +o xtrace
}

for file_path in "${affine_root}"/*
do
  file_base_name="$(basename -- $file_path)"

  cp_interp_img ${file_base_name} &
done

wait
