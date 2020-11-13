#!/bin/bash

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}/..
bash_config_file=${SRC_ROOT}/bash_config/20200225_deeds_reverse_label_multi_atlas.sh

echo "Create source images on atlas space"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}

#IMAGE_ATLAS=${DATA_ROOT}/atlas_full_resolution/atlas.nii.gz
#IMAGE_LABEL=${DATA_ROOT}/atlas_full_resolution/rib_and_spine.nii.gz

echo "Atlas image ${IMAGE_ATLAS}"
echo "Label image ${IMAGE_LABEL}"
echo

source_root=${OUT_ROOT}/source
ori_folder=${source_root}/ori
preprocess_folder=${source_root}/preprocess
reg_root=${source_root}/reg
label_folder=${source_root}/label

mkdir -p ${ori_folder}
mkdir -p ${preprocess_folder}
mkdir -p ${reg_root}
mkdir -p ${label_folder}

# 1. Preprocess images
#${SRC_ROOT}/tools/run_preprocess_folder.sh ${ori_folder} ${preprocess_folder} ${bash_config_file}

# 2. Register to atlas, then propagate the label map back to source image space.
for file_path in "${preprocess_folder}"/*.nii.gz
do
  start=`date +%s`

  file_base_name="$(basename -- $file_path)"
  target_image_name_no_ext="${file_base_name%%.*}"

  scan_reg_root=${reg_root}/${target_image_name_no_ext}
  mkdir -p ${scan_reg_root}
  fixed_img=${IMAGE_ATLAS}
  moving_img=${file_path}
  affine_path=${scan_reg_root}/affine
  affine_txt=${affine_path}_matrix.txt
  deformable_path=${scan_reg_root}/deformable
  invert_affine_txt=${scan_reg_root}/invert_affine.txt
  label_img=${IMAGE_LABEL}
  inverted_label_img=${scan_reg_root}/inverted_label.nii.gz
  out_label_img=${label_folder}/${target_image_name_no_ext}.nii.gz

  set -o xtrace
#  ${DEEDS_ROOT}/linearBCV -F ${fixed_img} -M ${moving_img} -O ${affine_path}
#  ${DEEDS_ROOT}/deedsBCVwinv -F ${fixed_img} -M ${moving_img} -O ${deformable_path} -A ${affine_txt}
  ${PYTHON_ENV} ${DEEDS_ROOT}/invert_matrix_txt.py --inputtxt ${affine_txt} --savetxt ${invert_affine_txt}
  ${DEEDS_ROOT}/applyBCVinv -M ${label_img} -O ${deformable_path} -D ${inverted_label_img} -A ${invert_affine_txt}
  cp ${inverted_label_img} ${out_label_img}
  set +o xtrace

  end=`date +%s`

  runtime=$((end-start))

  echo "Complete! Total ${runtime} (s)"
done
