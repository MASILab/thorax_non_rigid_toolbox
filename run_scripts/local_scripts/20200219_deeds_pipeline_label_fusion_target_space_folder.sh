#!/bin/bash

##################################################
# 2/3/2020 - Kaiwen
#What I thought as Input:
#
#5 demo scans (targets, unregistered images, from 5 different subjects): A1 – A5
#1 target scan (unregistered image, a different one from 5 demo cases): B
#1 Atlas: T
#Colored label map, labeled on atlas: L
#Procedure:
#
#Non-rigid register A1-A5 to T: A1_reg-A5_reg
#Non-rigid register A1_reg-A5_reg to B, so we have 5 transformation fields: Trans1 – Trans5
#Apply Trans1-Trans5 to 3 colored label map (labeled on atlas) L. So we have the label maps on 5 target: L1 – L5
#Overlapping to show the result
#L + B_reg
#L1-L5 + A1-A5
#Show majority vote and variable of L1 – L5
##################################################

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
      --reg_args_non_rigid ${reg_args} \
      --reg_args_affine ${reg_args} \
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