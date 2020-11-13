generate_bash_config_scan () {
  local out_config_path=$1
  local in_img_folder=$2
  local affine_out_root=$3
  local reference_img=$4

  mkdir -p ${affine_out_root}

  echo "Create configuration file ${out_config_path}"

  > ${out_config_path}
  echo "
# Pipeline substeps.
RUN_PREPROCESS=true
RUN_REGISTRATION=true
RUN_INTERPOLATION=true

# Run on accre
IS_ACCRE=false
DATA_ROOT=/nfs/masi/xuk9/SPORE
SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxAffine_for_non_rigid
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python
REG_TOOL_ROOT=/home/local/VANDERBILT/gaor2/bin_tool/rg/niftyreg
FSL_ROOT=/usr/local/fsl/bin
FREESURFER_ROOT=/nfs/masi/xuk9/local/freesurfer/bin
C3D_ROOT=/home/local/VANDERBILT/xuk9/src/c3d/bin

IN_ROOT=${in_img_folder}
# IN_DATASET_TYPE=hierarchy
IN_DATASET_TYPE=flat
OUT_ROOT=${affine_out_root}

IS_USE_SLURM=false
NUM_JOBS=10

# Preprocessing
IF_REUSE_PREPROCESS=false
PREPROCESS_REUSE_DIR=

IF_REMOVE_TEMP_FILES=false

IF_PREPROCESS_FIXED_IMAGE=false
IF_REUSE_FIXED_IMAGE=true
FIXED_IMAGE_ORI=
FIXED_IMAGE_REUSE=${reference_img}

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
  " >> ${out_config_path}

}

post_process_affine () {
  local in_folder=$1
  local roi_mask_img=$2
  local out_folder=$3

  echo "Mask interp image with atlas roi mask"
  echo ${in_folder}
  echo ${out_folder}

  mkdir -p ${out_folder}

  for file_path in "${in_folder}"/*
  do
    file_base_name="$(basename -- $file_path)"

    ori_img=${in_folder}/${file_base_name}
    out_img=${out_folder}/${file_base_name}

    set -o xtrace
    ${PYTHON_ENV} ${NON_RIGID_SRC_ROOT}/tools/apply_mask.py \
      --ori ${ori_img} \
      --mask ${roi_mask_img} \
      --out ${out_img} &
    set +o xtrace
  done
  wait
}

run_deeds_non_rigid_folder () {
  local in_folder=$1
  local out_temp_folder=$2
  local out_wrapped_folder=$3
  local fixed_img=$4
  local idendity_mat_txt=$5

  echo "Run non rigid deeds"

  mkdir -p ${out_temp_folder}
  mkdir -p ${out_wrapped_folder}

  wrap_one_img () {
    local scan_name=$1

    local flo_img=${in_folder}/${scan_name}.nii.gz
    local ref_img=${fixed_img}
    local deformable_path=${out_temp_folder}/${scan_name}
    local wrapped_img=${deformable_path}_deformed.nii.gz
    local out_img=${out_wrapped_folder}/${scan_name}.nii.gz

    set -o xtrace
    ${DEEDS_ROOT}/deedsBCVwinv \
      -ln 4 -G 7x6x5x4 -L 7x6x5x4 -Q 4x3x2x1 \
      -F ${ref_img} \
      -M ${flo_img} \
      -O ${deformable_path} \
      -A ${idendity_mat_txt}
    set +o xtrace

    set -o xtrace
    ${PYTHON_ENV} ${NON_RIGID_SRC_ROOT}/tools/reset_header_with_ref.py \
      --in-img ${wrapped_img} \
      --out-img ${out_img} \
      --ref-img ${ref_img}
    set +o xtrace
  }

  for file_path in "${in_folder}"/*.nii.gz
  do
    file_base_name="$(basename -- $file_path)"
    name_no_ext="${file_base_name%%.*}"

    wrap_one_img ${name_no_ext}
  done
}

create_lns_file_list () {
  local ori_folder=$1
  local file_list_txt=$2
  local out_ln_folder=$3

  mkdir -p ${out_ln_folder}
  while IFS= read -r file_name
  do
    local target_file=${ori_folder}/${file_name}
    local link_file=${out_ln_folder}/${file_name}
    echo "File name: $file_name"
    echo "Target file: ${target_file}"
    echo "Link file: ${link_file}"
    set -o xtrace
    if [ ! -f ${link_file} ]; then
      ln -s ${target_file} ${link_file}
    fi
    set +o xtrace
  done < "$file_list_txt"
}
