generate_affine_bash_config () {
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
DATA_ROOT=${DATA_ROOT}
SRC_ROOT=${AFFINE_SRC_ROOT}
PYTHON_ENV=${PYTHON_ENV}
REG_TOOL_ROOT=${NIFYREG_ROOT}
FSL_ROOT=${FSL_ROOT}
FREESURFER_ROOT=${FREESURFER_ROOT}
C3D_ROOT=${C3D_ROOT}

IN_ROOT=${in_img_folder}
# IN_DATASET_TYPE=hierarchy
IN_DATASET_TYPE=flat
OUT_ROOT=${affine_out_root}

IS_USE_SLURM=false
NUM_JOBS=10

# Preprocessing
IF_REUSE_PREPROCESS=false
PREPROCESS_REUSE_DIR=

IF_REMOVE_TEMP_FILES=true

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
REG_METHOD=affine_nifty_reg
REG_ARGS=\"\\\"\\\"\"

PRE_METHOD=mask_v1_ori_full
PRE_SCRIPT=reg_preprocess_ori_full_dim.sh

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

process_affine_scan () {
  local affine_config=$1
  local scan_name=$2

  ${AFFINE_SRC_ROOT}/run_reg_block_single.sh ${affine_config} ${scan_name}
}

generate_non_rigid_bash_config () {
  local out_config_path=$1
  local in_img_folder=$2
  local out_root=$3
  local reference_root=$4
  local in_mask_root=$5

  mkdir -p ${out_root}

  echo "Create configuration file ${out_config_path}"

  > ${out_config_path}
  echo "
# Runtime enviroment
SRC_ROOT=${NON_RIGID_SRC_ROOT}
PYTHON_ENV=${PYTHON_ENV}
IF_REMOVE_TEMP_FILES=true

# Method
METHOD_FUNCTION_SH=functions_corrField_non_rigid_fine_tune_1.sh

# Tools
TOOL_ROOT=\${SRC_ROOT}/packages
C3D_ROOT=\${TOOL_ROOT}/c3d
NIFYREG_ROOT=\${TOOL_ROOT}/niftyreg/bin
corrField_ROOT=\${TOOL_ROOT}/corrField

# corrField configuration
corrField_config_step1=\"-L 30x15 -a 1 -N 8x4 -R 6x4\"
effective_etch_step1=\"26\"
corrField_config_step2=\"-L 16x8 -a 0.7 -N 7x3 -R 6x4\"
effective_etch_step2=\"16\"
corrField_config_step3=\"-L 5x3 -a 0.5\"
effective_etch_step3=\"16\"
corrField_config_step4=\"-L 10x5 -a 0.1 -N 10x5 -R 6x4\"
effective_etch_step4=\"16\"

# Data
MOVING_FOLDER=${in_img_folder}
OUT_DATA_FOLDER=${out_root}
MASK_FOLDER=${in_mask_root}
REFERENCE_FOLDER=${reference_root}
FIXED_IMG=\${REFERENCE_FOLDER}/non_rigid.nii.gz
IDENTITY_MAT=\${REFERENCE_FOLDER}/idendity_matrix.txt

OUTPUT_ROOT_FOLDER=\${OUT_DATA_FOLDER}/output
OUTPUT_INTERP_FOLDER=\${OUT_DATA_FOLDER}/interp
OUTPUT_JAC_DET_FOLDER=\${OUT_DATA_FOLDER}/jac_det

mkdir -p \${OUTPUT_ROOT_FOLDER}
mkdir -p \${OUTPUT_INTERP_FOLDER}
mkdir -p \${OUTPUT_JAC_DET_FOLDER}

  " >> ${out_config_path}
}

process_non_rigid_scan () {
  local config=$1
  local scan_name=$2

  echo "Non-rigid Pipeline: process ${scan_name}"
  ${NON_RIGID_SRC_ROOT}/run_scripts/run_non_rigid_single_scan.sh \
    ${config} \
    ${scan_name}
}

generate_masi_slurm_job_array () {
  local out_config_path=$1
  local slurm_log_folder=$2
  local file_list_txt=$3
  local affine_config=$4
  local non_rigid_config=$5

  echo "Create slurm file ${out_config_path}"

  local num_scans=$(cat ${file_list_txt} | wc -l )
  local array_upper_bound=$(("${num_scans}"-1))

  > ${out_config_path}
  echo "#!/bin/bash

#SBATCH -J deeds_vlsp
#SBATCH --mail-user=kaiwen.xu@vanderbilt.edu
#SBATCH --mail-type=FAIL
#SBATCH --cpus-per-task=5
#SBATCH --nodes=1
#SBATCH --time=20:00:00
#SBATCH --mem=25G
#SBATCH --nice=10000000
#SBATCH -o ${slurm_log_folder}/scan_%A_%a.out
#SBATCH -e ${slurm_log_folder}/scan_%A_%a.err
#SBATCH --array=0-${array_upper_bound}

source ${CONFIG_FILE}
source ${NON_RIGID_SRC_ROOT}/tools/functions_affine_deformable_unit.sh

mapfile -t cmds < ${file_list_txt}
process_affine_scan ${affine_config} \${cmds[\$SLURM_ARRAY_TASK_ID]}
process_non_rigid_scan ${non_rigid_config} \${cmds[\$SLURM_ARRAY_TASK_ID]}
  " >> ${out_config_path}

}

generate_non_slurm_job_script () {
  local out_config_path=$1
  local affine_config=$2
  local non_rigid_config=$3

  echo "Create run bash file for scan ${out_config_path}"

  > ${out_config_path}
  echo "#!/bin/bash

SCAN_NAME=\"\$(basename -- \$1)\"

echo \"SERVER_ID: \${HOSTNAME}\"

source ${CONFIG_FILE}
source ${NON_RIGID_SRC_ROOT}/tools/functions_affine_deformable_singularity.sh

process_affine_scan ${affine_config} \${SCAN_NAME}
process_non_rigid_scan ${non_rigid_config} \${SCAN_NAME}
  " >> ${out_config_path}

}

create_lns_file_list () {
  local ori_folder=$1
  local file_list_txt=$2
  local out_ln_folder=$3

  echo "Create ln from ${out_ln_folder} to ${ori_folder}"
  mkdir -p ${out_ln_folder}
  while IFS= read -r file_name
  do
    local target_file=${ori_folder}/${file_name}
    local link_file=${out_ln_folder}/${file_name}
#    echo "File name: $file_name"
#    echo "Target file: ${target_file}"
#    echo "Link file: ${link_file}"
    set -o xtrace
    if [ ! -f ${link_file} ]; then
      ln -s ${target_file} ${link_file}
    fi
    set +o xtrace
  done < "$file_list_txt"
  local number_files=$(ls ${out_ln_folder} | wc -l)
  echo "Done. Number of files ${number_files}"
}
