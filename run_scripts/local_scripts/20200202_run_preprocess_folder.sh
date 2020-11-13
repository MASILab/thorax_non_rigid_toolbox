#!/bin/bash

##################################################
# 2/2/2020 - Kaiwen
# Build pipeline for thorax non-rigid registration.
##################################################

#SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxNonRigid
#bash_config_file=${SRC_ROOT}/bash_config/20200202_non_rigid_deeds_image2image_label.sh

echo "Preprocess pipeline"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}

#in_folder=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/nonrigid_deedsBCV/demo_cases_1
#out_folder=${OUT_ROOT}/preprocess_1

in_folder=$(readlink -f $1)
out_folder=$(readlink -f $2)

echo "In folder ${in_folder}"
echo "Out folder ${out_folder}"

temp_folder=${out_folder}/temp
mkdir -p ${temp_folder}

for file_path in "$in_folder"/*
do
  file_base_name="$(basename -- $file_path)"
  out_file_path=${out_folder}/${file_base_name}
  ${SRC_ROOT}/tools/reg_preprocess_resample_pad_res.sh ${bash_config_file} ${file_path} ${out_file_path} ${temp_folder}
done
