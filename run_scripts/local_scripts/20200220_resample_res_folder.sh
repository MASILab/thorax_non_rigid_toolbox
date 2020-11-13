#!/bin/bash

##################################################
# 2/20/2020 - Kaiwen Xu
# Resample and reset the origin of all images under a folder.

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

in_image_folder=/home/local/VANDERBILT/xuk9/cur_data_dir/registration/deedsBCV_family/20191107_config3/reg

OUT_ROOT=/nfs/masi/xuk9/SPORE/registration/label_propagation/20200220_count_success_rate
out_header_reset=${OUT_ROOT}/header_res
out_origin_reset=${OUT_ROOT}/ori_res
out_iso=${OUT_ROOT}/iso

mkdir -p ${out_header_reset}
mkdir -p ${out_origin_reset}
mkdir -p ${out_iso}

ref_atlas_img=/nfs/masi/xuk9/SPORE/registration/nonrigid_deedsBCV/20200129_1_3_rd/atlas.nii.gz
ref_mask_img=/nfs/masi/xuk9/SPORE/registration/nonrigid_deedsBCV/20200129_1_3_rd/mask.nii.gz

reset_single_image () {
  local in_image=$1

  echo
  echo "Process image ${in_image}"

  image_name="$(basename -- ${in_image})"
  out_header_reset_img=${out_header_reset}/${image_name}
  out_origin_reset_img=${out_origin_reset}/${image_name}
  out_iso_img=${out_iso}/${image_name}

  set -o xtrace

  ${PYTHON_ENV} ${SRC_ROOT}/tools/reset_header_with_ref.py \
    --in-img ${in_image} \
    --ref-img ${ref_atlas_img} \
    --out-img ${out_header_reset_img}

  ${PYTHON_ENV} ${SRC_ROOT}/tools/set_image_origin_to_lung_mask_center.py \
    --in_image ${out_header_reset_img} \
    --in_mask ${ref_mask_img} \
    --out ${out_origin_reset_img} \
    --c3d_root ${C3D_ROOT}

  ${C3D_ROOT}/c3d ${out_origin_reset_img} \
    -resample-mm 1x1x1mm \
    -o ${out_iso_img}

  set +o xtrace
}

for in_image in "${in_image_folder}"/*.nii.gz
do
  reset_single_image ${in_image}
done