#!/bin/bash

# example file. Put this into the project root folder and run.

source /src/Thorax_non_rigid_combine/bash_config/singularity/config_niftyreg_corrField.sh

SRC_ROOT=${NON_RIGID_SRC_ROOT}

PROJ_ROOT=/proj_root
REFERENCE_ROOT=${PROJ_ROOT}/reference
NON_RIGID_ROOT=${PROJ_ROOT}/output/non_rigid
NON_RIGID_INTERP_ROOT=${NON_RIGID_ROOT}/interp

ANALYSIS_ROOT=${PROJ_ROOT}/analysis
DATA_LIST=${ANALYSIS_ROOT}/file_list
ANALYSIS_METRIC_ROOT=${ANALYSIS_ROOT}/metric
ANALYSIS_DICE_ROOT=${ANALYSIS_METRIC_ROOT}/dice
DICE_VALID_REGION_MASK_FOLDER=${ANALYSIS_DICE_ROOT}/dice_effective_region
mkdir -p ${ANALYSIS_DICE_ROOT}
mkdir -p ${DICE_VALID_REGION_MASK_FOLDER}

METRIC_ETCH_RADIUS="1"

MASKED_FOLDER=${ANALYSIS_ROOT}/gen_template/masked_folder

get_dice_with_effective_region_flag () {
  local mask_flag="$1"
  local dice_valid_region_mask_folder=${DICE_VALID_REGION_MASK_FOLDER}/${mask_flag}
  local in_mask_folder=${NON_RIGID_INTERP_ROOT}/${mask_flag}

  local ref_valid_region_mask=${REFERENCE_ROOT}/valid_region_mask.nii.gz
  local ref_gt_mask=${REFERENCE_ROOT}/${mask_flag}.nii.gz

  local out_csv=${ANALYSIS_DICE_ROOT}/${mask_flag}.csv

  set -o xtrace
  mkdir -p ${dice_valid_region_mask_folder}

  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_dice_effective_region.py \
    --in-ori-folder ${MASKED_FOLDER} \
    --file-list-txt ${DATA_LIST} \
    --in-ref-valid-mask ${ref_valid_region_mask} \
    --out-folder ${dice_valid_region_mask_folder} \
    --etch-radius ${METRIC_ETCH_RADIUS} \
    --num-process 50

  ${PYTHON_ENV} ${SRC_ROOT}/tools/get_dice_statics.py \
    --in-folder ${in_mask_folder} \
    --in-effective-mask-folder ${dice_valid_region_mask_folder} \
    --file-list-txt ${DATA_LIST} \
    --gt-mask ${ref_gt_mask} \
    --out-csv ${out_csv} \
    --num-process 50
  set +o xtrace
}

get_dice_with_effective_region_flag lung_mask
get_dice_with_effective_region_flag body_mask
