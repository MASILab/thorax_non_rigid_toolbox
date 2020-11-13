#!/bin/bash

##################################################
# 2/20/2020 - Kaiwen Xu
# Preprocess original image, using the

#bash_config_file=$(readlink -f $1)
#in_folder=$(readlink -f $2)
#reg_folder=$(readlink -f $3)

#SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxNonRigid
BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200218_non_rigid_deeds_same_registration_config.sh

echo "Create source images on atlas space"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}

target_image_folder=${OUT_ROOT}/target_list/preprocessed

label_map=${OUT_ROOT}/atlas/rib.nii.gz
fusion_temp=${OUT_ROOT}/label_fusion
source_image_folder=${OUT_ROOT}/source_image/reg
NUM_LABELS=13

propagate_label_single_image () {
  local target_image=$1

  echo
  echo "Generate label map for image ${target_image}"

  target_image_name="$(basename -- ${target_image})"
  target_image_name_no_ext="${target_image_name%%.*}"

  target_temp_root=${fusion_temp}/${target_image_name_no_ext}
  reg_folder=${target_temp_root}/reg
  omat_folder=${target_temp_root}/omat
  label_folder=${target_temp_root}/label
  fused_label_path=${target_temp_root}/label.nii.gz
  mkdir -p ${target_temp_root}
  mkdir -p ${reg_folder}
  mkdir -p ${omat_folder}
  mkdir -p ${label_folder}

  for file_path in "${source_image_folder}"/*.nii.gz
  do
    start=`date +%s`

    file_base_name="$(basename -- $file_path)"

    out_file_path=${reg_folder}/${file_base_name}

    fixed_img=${target_image}
    moving_img=${file_path}
    out_img=${out_file_path}
    omat_txt=${omat_folder}/${file_base_name}
    reg_tool_root=${REG_TOOL_ROOT}
    reg_method=deformable_deedsBCV_paral
    reg_args="\"-l_3_-G_8x7x6_-L_8x7x6_-Q_5x4x3\""

    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/reg_thorax_non_rigid.py \
      --fixed ${fixed_img} \
      --moving ${moving_img} \
      --out ${out_img} \
      --omat ${omat_txt} \
      --reg_tool_root ${reg_tool_root} \
      --reg_method ${reg_method} \
      --reg_args ${reg_args} \
      --label ${label_map}
    set +o xtrace

    end=`date +%s`

    runtime=$((end-start))

    echo "Complete! Total ${runtime} (s)"
  done

  cp ${reg_folder}/*seg* ${label_folder}

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/majority_vote.py \
    --in-folder ${label_folder} \
    --out ${fused_label_path} \
    --num-class ${NUM_LABELS}
  set +o xtrace
}

for target_file_path in "${target_image_folder}"/*.nii.gz
do
  propagate_label_single_image ${target_file_path}
done