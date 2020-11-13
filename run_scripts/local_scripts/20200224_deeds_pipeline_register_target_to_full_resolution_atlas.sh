#!/bin/bash

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200218_non_rigid_deeds_same_registration_config.sh

echo "Create source images on atlas space"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}

IMAGE_ATLAS=${DATA_ROOT}/atlas_full_resolution/atlas.nii.gz
IMAGE_LABEL=${DATA_ROOT}/atlas_full_resolution/rib_and_spine.nii.gz

echo "Atlas image ${IMAGE_ATLAS}"
echo

omat_folder=${OUT_ROOT}/target_reg_full_resolution/omat
reg_folder=${OUT_ROOT}/target_reg_full_resolution/reg
mkdir -p ${omat_folder}
mkdir -p ${reg_folder}

preprocessed_image_folder=${DATA_ROOT}/target_list/preprocessed_full_resolution

for file_path in "${preprocessed_image_folder}"/*.nii.gz
do
  start=`date +%s`

  file_base_name="$(basename -- $file_path)"
  out_file_path=${reg_folder}/${file_base_name}

  fixed_img=${IMAGE_ATLAS}
  moving_img=${file_path}
  out_img=${out_file_path}
  omat_txt=${omat_folder}/${file_base_name}
  reg_tool_root=${REG_TOOL_ROOT}
  reg_method=deformable_deedsBCV_paral
  reg_args="\"-l_3_-G_8x7x6_-L_8x7x6_-Q_5x4x3\""
#  label=${atlas_label}

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/reg_thorax_non_rigid.py \
    --fixed ${fixed_img} \
    --moving ${moving_img} \
    --out ${out_img} \
    --omat ${omat_txt} \
    --reg_tool_root ${reg_tool_root} \
    --reg_method ${reg_method} \
    --reg_args_non_rigid ${reg_args} \
    --reg_args_affine ${reg_args}
  set +o xtrace

  end=`date +%s`

  runtime=$((end-start))

  echo "Complete! Total ${runtime} (s)"
done
