#!/bin/bash

##################################################
# 2/5/2020 - Kaiwen
# Revert back transformation fields under a folder.
##################################################

SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxNonRigid
bash_config_file=${SRC_ROOT}/bash_config/20200203_non_rigid_niftyreg_image2image_label.sh

echo "Non-rigid pipeline -- revert and interpolate deformation field"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}

project_folder=${OUT_ROOT}/reg_folder2atlas_10vox
trans_revert_folder=${project_folder}/trans_revert
interp_label_folder=${project_folder}/interp_label
mkdir -p ${trans_revert_folder}
mkdir -p ${interp_label_folder}

trans_folder=${project_folder}/trans
refs_folder=${OUT_ROOT}/preprocess
label_img=${OUT_ROOT}/atlas/labels_iso.nii.gz

echo
echo "Transformation folder ${trans_folder}"
echo "Label image ${label_img}"
echo "Output revert trans folder ${trans_revert_folder}"
echo "Output interp label folder ${interp_label_folder}"
echo

for file_path in "$trans_folder"/*
do
  start=`date +%s`

  file_base_name="$(basename -- $file_path)"
  trans=${trans_folder}/${file_base_name}
  trans_revert=${trans_revert_folder}/${file_base_name}
  moving_img=${label_img}
  out_img=${interp_label_folder}/${file_base_name}
  ref_img=${refs_folder}/${file_base_name}

  set -o xtrace
  ${REG_TOOL_ROOT}/reg_transform \
    -ref ${ref_img} \
    -invNrr ${trans} ${moving_img} ${trans_revert}
  set +o xtrace

  set -o xtrace
  ${REG_TOOL_ROOT}/reg_resample \
   -ref ${ref_img}\
   -flo ${moving_img}\
   -trans ${trans_revert}\
   -res ${out_img}\
   -inter 0\
   -pad 0\
   -omp ${NUM_PROCESSES}
  set +o xtrace

  end=`date +%s`

  runtime=$((end-start))

  echo "Complete! Total ${runtime} (s)"
done

