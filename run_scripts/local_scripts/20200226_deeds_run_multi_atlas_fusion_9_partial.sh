#!/bin/bash

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Create source images on atlas space"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}

#IMAGE_ATLAS=${DATA_ROOT}/atlas_full_resolution/atlas.nii.gz
#IMAGE_LABEL=${DATA_ROOT}/atlas_full_resolution/rib_and_spine.nii.gz

#echo "Atlas image ${IMAGE_ATLAS}"
#echo "Label image ${IMAGE_LABEL}"
echo

source_root=${OUT_ROOT}/source
source_preprocessed_folder=${source_root}/preprocess
source_label_folder=${source_root}/label

target_root=${OUT_ROOT}/target
target_ori_folder=${target_root}/ori
target_preprocessed_folder=${target_root}/preprocess
target_reg_root=${target_root}/reg
target_label_folder=${target_root}/label

mkdir -p ${target_preprocessed_folder}
mkdir -p ${target_reg_root}
mkdir -p ${target_label_folder}

# 1. Preprocess images
#${SRC_ROOT}/tools/run_preprocess_folder.sh ${target_ori_folder} ${target_preprocessed_folder} ${bash_config_file}

# 2. Register the 9 atlas to each of the 5 images, then do label fusion.

run_multi_atlas () {
  local fixed_img=$1
  local multi_atlas_root=$2

  start=`date +%s`
  echo
  echo "Run multi-atlas to label image ${fixed_img}"
  echo "Atlas images under folder ${source_preprocessed_folder}"
  echo "Atlas labels under folder ${source_label_folder}"

  label_folder=${multi_atlas_root}/label
  mkdir -p ${label_folder}

  for source_img_path in "${source_preprocessed_folder}"/*.nii.gz
  do
    file_base_name="$(basename -- $source_img_path)"
    source_image_name_no_ext="${file_base_name%%.*}"

    echo
    echo "Register source image ${source_img_path} to target image ${fixed_img}"

    multi_atlas_source_reg_root=${multi_atlas_root}/${source_image_name_no_ext}
    mkdir -p ${multi_atlas_source_reg_root}
    moving_img=${source_img_path}
    affine_path=${multi_atlas_source_reg_root}/affine
    affine_txt=${affine_path}_matrix.txt
    deformable_path=${multi_atlas_source_reg_root}/deformable
    label_img=${source_label_folder}/${file_base_name}
    deformed_label_img=${deformable_path}_deformed_seg.nii.gz
    output_label_img=${label_folder}/${file_base_name}

    set -o xtrace
    if [ ! -f "${affine_txt}" ]; then
      ${DEEDS_ROOT}/linearBCV -F ${fixed_img} -M ${moving_img} -O ${affine_path}
    fi
    if [ ! -f "${deformed_label_img}" ]; then
      ${DEEDS_ROOT}/deedsBCVwinv -F ${fixed_img} -M ${moving_img} -O ${deformable_path} -A ${affine_txt} -S ${label_img}
    fi
    cp ${deformed_label_img} ${output_label_img}
    set +o xtrace
  done

  echo
  echo "Registration complete, start label fusion"
  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/majority_vote.py \
    --in-folder ${label_folder} \
    --out ${multi_atlas_root}/label.nii.gz \
    --num-class 13
  set +o xtrace

  end=`date +%s`
  runtime=$((end-start))

  echo "run_multi_atlas complete! total ${runtime} (s)"
}

# only run second half,
for file_path in "${target_preprocessed_folder}"/{00000919time20180319.nii.gz,00001103time20180418.nii.gz}
do
  start=`date +%s`

  file_base_name="$(basename -- $file_path)"
  target_image_name_no_ext="${file_base_name%%.*}"

  target_scan_reg_root=${target_reg_root}/${target_image_name_no_ext}
  mkdir -p ${target_scan_reg_root}
  fixed_img=${file_path}

  run_multi_atlas ${fixed_img} ${target_scan_reg_root}

  set -o xtrace
  cp ${target_scan_reg_root}/label.nii.gz ${target_label_folder}/${file_base_name}
  set +o xtrace

  end=`date +%s`

  runtime=$((end-start))

  echo "${file_path}"
  echo "Complete! Total ${runtime} (s)"
done
