generate_accre_script_job_array () {
  local out_config_path=${SLURM_BATCH_FILE}

  echo "Create configuration file ${out_config_path}"

  local array_upper_bound=$((${NUMBER_SCAN}-1))

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
#SBATCH -o ${SLURM_LOG_FOLDER}/scan_%A_%a.out
#SBATCH -e ${SLURM_LOG_FOLDER}/scan_%A_%a.err
#SBATCH --array=0-${array_upper_bound}

module purge
module restore deedsBCV_family
export FREESURFER_HOME=/home/xuk9/local/freesurfer
source \$FREESURFER_HOME/SetUpFreeSurfer.sh

source ${CONFIG_FILE}
source ${SRC_ROOT}/tools/accre_vlsp_functions.sh

mapfile -t cmds < ${FILE_LIST_TXT}
process_non_rigid_deeds \${cmds[\$SLURM_ARRAY_TASK_ID]}
  " >> ${out_config_path}

}


generate_masi_slurm_job_array () {
  local out_config_path=${SLURM_BATCH_FILE}

  echo "Create configuration file ${out_config_path}"

  local array_upper_bound=$((${NUMBER_SCAN}-1))

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
#SBATCH -o ${SLURM_LOG_FOLDER}/scan_%A_%a.out
#SBATCH -e ${SLURM_LOG_FOLDER}/scan_%A_%a.err
#SBATCH --array=0-${array_upper_bound}

source ${CONFIG_FILE}
source ${SRC_ROOT}/tools/accre_vlsp_functions.sh

mapfile -t cmds < ${FILE_LIST_TXT}
process_non_rigid_deeds \${cmds[\$SLURM_ARRAY_TASK_ID]}
  " >> ${out_config_path}

}

process_non_rigid_deeds () {
  local scan_name=$1
  local scan_name_no_ext="${scan_name%%.*}"

  # 1. Mask image with atlas roi.
  local affine_interp_img=${IN_DATA_FOLDER}/${scan_name}
  local masked_img=${OUT_MASKED_INPUT_FOLDER}/${scan_name}

  if [ ! -f "${masked_img}" ]; then
    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/apply_mask.py \
      --ori ${affine_interp_img} \
      --mask ${ROI_MASK_IMG} \
      --out ${masked_img}
    set +o xtrace
  fi

  # 2. Replace nan to -1000
  # Integrated in apply_mask.py

  # 3. Registration with deeds.
  local flo_img=${masked_img}
  local ref_img=${REFERENCE_IMG}
  local scan_deeds_out_folder=${OUT_DEEDS_OUTPUT_FOLDER}/${scan_name_no_ext}
  mkdir -p ${scan_deeds_out_folder}
  local deformable_path=${scan_deeds_out_folder}/non_rigid
  local deeds_output_deformable_img=${deformable_path}_deformed.nii.gz
  local output_wrapped_img=${OUT_WRAPPED_FOLDER}/${scan_name}
  local deeds_output_trans_dat=${deformable_path}_displacements.dat
  local output_trans_dat=${OUT_DEEDS_TRANS_FOLDER}/${scan_name}_displacements.dat

  local DEEDS_ARGS="-ln 4 -G 7x6x5x4 -L 7x6x5x4 -Q 4x3x2x1"
  if [ ! -f "${output_wrapped_img}" ]; then
    set -o xtrace
    ${DEEDS_ROOT}/deedsBCVwinv \
      ${DEEDS_ARGS} \
      -F ${ref_img} \
      -M ${flo_img} \
      -O ${deformable_path} \
      -A ${IDD_MAT}
    set +o xtrace

    set -o xtrace
    ${PYTHON_ENV} ${SRC_ROOT}/tools/reset_header_with_ref.py \
      --in-img ${deeds_output_deformable_img} \
      --out-img ${output_wrapped_img} \
      --ref-img ${ref_img}

    mv ${deeds_output_trans_dat} ${output_trans_dat}
    set +o xtrace
  fi

  # 4. Remove temp files if necessary.
  if [ "$IF_REMOVE_TEMP_FILES" = true ] ; then
    echo "Removing temp files..."
      set -o xtrace
      rm -f ${masked_img}
      rm -f ${deeds_output_deformable_img}
      set +o xtrace
    echo "Done."
  fi
}

interpolate_masks () {
  local scan_name=$1
  local scan_name_no_ext="${scan_name%%.*}"

  local trans_dat=${OUT_DEEDS_TRANS_FOLDER}/${scan_name}

  interpolate_mask () {
    local flag="$1"
    local in_mask=${IN_MASK_ROLDER}/${flag}/${scan_name}

    local out_mask_folder=${OUT_INTERP_MASK_FOLDER}/${flag}
    mkdir -p ${out_mask_folder}
    local out_mask=${out_mask_folder}/${scan_name}

    set -o xtrace
    ${DEEDS_ROOT}/applyBCV \
      -M ${in_mask} \
      -O ${trans_dat} \
      -D ${out_mask}
    set +o xtrace
  }

  interpolate_ori () {
    local flag="$1"
    local in_mask=${IN_MASK_ROLDER}/${flag}/${scan_name}

    local out_mask_folder=${OUT_INTERP_MASK_FOLDER}/${flag}
    mkdir -p ${out_mask_folder}
    local out_mask=${out_mask_folder}/${scan_name}

    set -o xtrace
    ${DEEDS_ROOT}/applyBCVfloat \
      -M ${in_mask} \
      -O ${trans_dat} \
      -D ${out_mask}
    set +o xtrace
  }

  echo ""
#  echo "Interpolate body_mask"
#  interpolate_mask "body_mask"
#  echo "Interpolate lung_mask"
#  interpolate_mask "lung_mask"
  echo "Interpolate moving scan"
  interpolate_ori "ori"
}
