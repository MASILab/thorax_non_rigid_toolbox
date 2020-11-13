#!/bin/bash

##################################################
# 3/17/2020 - Kaiwen
# A new pipeline that combining
# 1) nifty affine
# 2) deeds non-rigid
# 3) slurm
##################################################

CONFIG_FILE=$(readlink -f $1)
source ${CONFIG_FILE}
source ${NON_RIGID_SRC_ROOT}/tools/functions_affine_deformable_unit.sh

SPLIT_DATA_ROOT=${PROJ_ROOT}/data
OUT_DATA_FOLDER=${PROJ_ROOT}/output
OUT_VLSP_DATA_FOLDER=${PROJ_ROOT}/output_vlsp
VLSP_DATASET_ROOT=${SPLIT_DATA_ROOT}/vlsp_datasets
mkdir -p ${OUT_DATA_FOLDER}
mkdir -p ${OUT_VLSP_DATA_FOLDER}
mkdir -p ${VLSP_DATASET_ROOT}

run_gender_atlas () {
  local gender_flag=$1

  local file_list=${SPLIT_DATA_ROOT}/file_lists/${gender_flag}_50.txt
  local gender_out_root=${OUT_DATA_FOLDER}/${gender_flag}
  mkdir -p ${gender_out_root}
  local gender_in_data_folder=${SPLIT_DATA_ROOT}/${gender_flag}
  local ref_affine_img=${SPLIT_DATA_ROOT}/reference/${gender_flag}_thr.nii.gz
  local ref_non_rigid_img=${SPLIT_DATA_ROOT}/reference/${gender_flag}.nii.gz

  # 1. Generate configuration file for affine
  AFFINE_ROOT=${gender_out_root}/affine
  mkdir -p ${AFFINE_ROOT}
  AFFINE_CONFIG=${AFFINE_ROOT}/config.sh
  generate_affine_bash_config \
    ${AFFINE_CONFIG} \
    ${gender_in_data_folder} \
    ${AFFINE_ROOT} \
    ${ref_affine_img}
  ${AFFINE_SRC_ROOT}/run_reg_block_prepare.sh ${AFFINE_CONFIG}

  # 2. Generate configuration file for non-rigid
  NON_RIGID_ROOT=${gender_out_root}/non_rigid
  mkdir -p ${NON_RIGID_ROOT}
  NON_RIGID_INPUT_FOLDER=${AFFINE_ROOT}/interp/ori
  NON_RIGID_CONFIG=${NON_RIGID_ROOT}/config.sh
  generate_non_rigid_bash_config \
    ${NON_RIGID_CONFIG} \
    ${NON_RIGID_INPUT_FOLDER} \
    ${NON_RIGID_ROOT} \
    ${ref_non_rigid_img} \
    ${file_list}

  # 3. Generate the slurm file.
  SLURM_FILE=${gender_out_root}/run_slurm.sh
  SLURM_LOG_FOLDER=${gender_out_root}/log
  mkdir -p ${SLURM_LOG_FOLDER}
  generate_masi_slurm_job_array \
    ${SLURM_FILE} \
    ${SLURM_LOG_FOLDER} \
    ${file_list} \
    ${AFFINE_CONFIG} \
    ${NON_RIGID_CONFIG}

  # 4. Run slurm
  sbatch --exclude=felakuti,kyuss,melvins,pelican,slayer ${SLURM_FILE}
}

run_gender_vlsp_non_rigid () {
  local gender_flag=$1

  local gender_out_atlas_root=${OUT_DATA_FOLDER}/${gender_flag}
  local NON_RIGID_ROOT=${gender_out_atlas_root}/non_rigid
  local ref_non_rigid_img=${SPLIT_DATA_ROOT}/reference/${gender_flag}.nii.gz

  # Generate atlas
  OUT_TEMPLATE=${gender_out_atlas_root}/template.nii.gz
  OUT_TEMPLATE_THR=${gender_out_atlas_root}/template_thr.nii.gz
  set -o xtrace
  ${PYTHON_ENV} ${NON_RIGID_SRC_ROOT}/tools/average_images.py \
    --in_folder ${NON_RIGID_ROOT}/wrapped \
    --out ${OUT_TEMPLATE} \
    --ref ${ref_non_rigid_img} \
    --num_processes 10
  reg_clip_intensity ${OUT_TEMPLATE} ${OUT_TEMPLATE_THR}
  set +o xtrace

  # Create lns
  local file_list=${SPLIT_DATA_ROOT}/file_lists/${gender_flag}.txt
  local dataset_folder=${VLSP_DATASET_ROOT}/${gender_flag}
  mkdir -p ${dataset_folder}
  create_lns_file_list \
    ${IN_DATA_FOLDER} \
    ${file_list} \
    ${dataset_folder}

  ###########################
  # Registraton
  local gender_out_root=${OUT_VLSP_DATA_FOLDER}/${gender_flag}
  mkdir -p ${gender_out_root}
  local gender_in_data_folder=${dataset_folder}
  local ref_affine_img=${OUT_TEMPLATE_THR}
  local ref_non_rigid_img=${OUT_TEMPLATE}

  # Generate configuration file for affine
  AFFINE_ROOT=${gender_out_root}/affine
  mkdir -p ${AFFINE_ROOT}
  AFFINE_CONFIG=${AFFINE_ROOT}/config.sh
  generate_affine_bash_config \
    ${AFFINE_CONFIG} \
    ${gender_in_data_folder} \
    ${AFFINE_ROOT} \
    ${ref_affine_img}
  ${AFFINE_SRC_ROOT}/run_reg_block_prepare.sh ${AFFINE_CONFIG}

  # Generate configuration file for non-rigid
  NON_RIGID_ROOT=${gender_out_root}/non_rigid
  mkdir -p ${NON_RIGID_ROOT}
  NON_RIGID_INPUT_FOLDER=${AFFINE_ROOT}/interp/ori
  NON_RIGID_CONFIG=${NON_RIGID_ROOT}/config.sh
  generate_non_rigid_bash_config \
    ${NON_RIGID_CONFIG} \
    ${NON_RIGID_INPUT_FOLDER} \
    ${NON_RIGID_ROOT} \
    ${ref_non_rigid_img} \
    ${file_list}

  # Generate the slurm file.
  SLURM_FILE=${gender_out_root}/run_slurm.sh
  SLURM_LOG_FOLDER=${gender_out_root}/log
  mkdir -p ${SLURM_LOG_FOLDER}
  generate_masi_slurm_job_array \
    ${SLURM_FILE} \
    ${SLURM_LOG_FOLDER} \
    ${file_list} \
    ${AFFINE_CONFIG} \
    ${NON_RIGID_CONFIG}

  # Run slurm
  sbatch --exclude=felakuti,kyuss,melvins,pelican,slayer ${SLURM_FILE}
}

#gender_array=("female" "male_1092" "male_103" "male_318" "male_825" "male_954")
gender_array=("male_1092" "male_825")
for gender_flag in "${gender_array[@]}"
do
  echo "${gender_flag}"
#  run_gender_atlas ${gender_flag}
  run_gender_vlsp_non_rigid ${gender_flag}
done