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

atlas_folder=${DATA_ROOT}/multi_atlas/atlas_thr
#label_folder=${DATA_ROOT}/multi_atlas/label_refine
affine_scan_folder=${DATA_ROOT}/affine/scans
in_img_folder=${DATA_ROOT}/data_1

mkdir -p ${affine_scan_folder}

generate_bash_config_scan () {
  local scan_name=$1

  local out_scan_root=${affine_scan_folder}/${scan_name}
  mkdir -p ${out_scan_root}
  local out_config_sh=${out_scan_root}/bash_config.sh
  local atlas_img=${atlas_folder}/${scan_name}.nii.gz

  echo "Create configuration file ${out_config_sh}"

  > ${out_config_sh}
  echo "
# Pipeline substeps.
RUN_PREPROCESS=true
RUN_REGISTRATION=true
RUN_INTERPOLATION=true

# Run on accre
IS_ACCRE=false
DATA_ROOT=/nfs/masi/xuk9/SPORE
SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxRegistration
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python
REG_TOOL_ROOT=/home/local/VANDERBILT/gaor2/bin_tool/rg/niftyreg
FSL_ROOT=/usr/local/fsl/bin
FREESURFER_ROOT=/nfs/masi/xuk9/local/freesurfer/bin
C3D_ROOT=/home/local/VANDERBILT/xuk9/src/c3d/bin

IN_ROOT=${in_img_folder}
# IN_DATASET_TYPE=hierarchy
IN_DATASET_TYPE=flat
OUT_ROOT=${out_scan_root}

IS_USE_SLURM=false
NUM_JOBS=1

# Preprocessing
IF_REUSE_PREPROCESS=false
PREPROCESS_REUSE_DIR=

IF_REMOVE_TEMP_FILES=false

IF_PREPROCESS_FIXED_IMAGE=false
IF_REUSE_FIXED_IMAGE=true
FIXED_IMAGE_ORI=
FIXED_IMAGE_REUSE=${atlas_img}

SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=450
DIM_Y=450
DIM_Z=400

# EXEs

#REG_TOOL_ROOT=/usr/local/fsl/bin
#REG_METHOD=affine_flirt
#REG_TOOL_ROOT=/fs4/masi/baos1/deeds_bk/deedsBCV
#REG_METHOD=affine_deedsBCV
REG_METHOD=affine_nifty_reg
#REG_METHOD=affine_nifty_reg_mask
REG_ARGS=\"\\\"\\\"\"

#PRE_METHOD=roi_v2_intens_clip
PRE_METHOD=mask_v1_ori_full
#PRE_SCRIPT=reg_preprocess.sh
PRE_SCRIPT=reg_preprocess_ori_full_dim.sh

#INTERP_METHOD=clipped_ori
#INTERP_METHOD=full_ori
INTERP_METHOD=roi_lung_mask

MAT_OUT=\${OUT_ROOT}/omat
REG_OUT=\${OUT_ROOT}/reg
PREPROCESS_OUT=\${OUT_ROOT}/preprocess
INTERP_OUT=\${OUT_ROOT}/interp
SLURM_DIR=\${OUT_ROOT}/slurm
LOG_DIR=\${OUT_ROOT}/log
TEMP_DIR=\${OUT_ROOT}/temp
FIXED_IMAGE_DIR=\${OUT_ROOT}/fixed_image
STATIC_OUT=\${OUT_ROOT}/out
COMPLETE_TASK_DIR=\${OUT_ROOT}/complete
COMPLETE_PREPROCESS_DIR=\${COMPLETE_TASK_DIR}/preprocess
COMPLETE_REGISTRATION_DIR=\${COMPLETE_TASK_DIR}/registration
COMPLETE_INTERPOLATION_DIR=\${COMPLETE_TASK_DIR}/interpolation

FIXED_IMAGE=\${FIXED_IMAGE_DIR}/fixed_image.nii.gz
  " >> ${out_config_sh}

}

for file_path in "${atlas_folder}"/*.nii.gz
do
  file_base_name="$(basename -- $file_path)"
  atlas_image_name_no_ext="${file_base_name%%.*}"

  generate_bash_config_scan ${atlas_image_name_no_ext}
done
