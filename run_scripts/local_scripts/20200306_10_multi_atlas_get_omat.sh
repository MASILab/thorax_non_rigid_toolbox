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
out_omat_folder=${DATA_ROOT}/affine/output/${flo_img_name_no_ext}/omat

mkdir -p ${out_omat_folder}

cp_omat_img () {
  local scan_name=$1

  local in_txt=${affine_root}/${scan_name}/omat/${flo_img_name_no_ext}.txt
  local out_txt=${out_omat_folder}/${scan_name}.txt

  set -o xtrace
  cp ${in_txt} ${out_txt}
  set +o xtrace
}

for file_path in "${affine_root}"/*
do
  file_base_name="$(basename -- $file_path)"

  cp_omat_img ${file_base_name} &
done

wait
