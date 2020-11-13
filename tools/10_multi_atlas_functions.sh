
generate_bash_config_scan () {
  local atlas_name=$1
  local affine_output_root=$2
  local atlas_folder=$3
  local in_img_folder=$4

  local out_scan_root=${affine_output_root}/${atlas_name}
  mkdir -p ${out_scan_root}
  local out_config_sh=${out_scan_root}/bash_config.sh
  local atlas_img=${atlas_folder}/${atlas_name}.nii.gz

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
NUM_JOBS=10

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

run_niftyreg_affine_atlas () {
  local atlas_name=$1
  local affine_output_root=$2

  local out_scan_root=${affine_output_root}/${atlas_name}
  local config_sh=${out_scan_root}/bash_config.sh

  set -o xtrace
  ${AFFINE_SRC_ROOT}/run_reg_block.sh ${config_sh}
  set +o xtrace
}