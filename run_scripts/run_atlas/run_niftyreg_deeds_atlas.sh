#!/bin/bash

##################################################
# 3/7/2020 - Kaiwen
# Niftyreg (affine) + Deeds (non-rigid) pipeline
##################################################

CONFIG_FILE=$(readlink -f $1)
source ${CONFIG_FILE}
source ${NON_RIGID_SRC_ROOT}/tools/atlas_built_functions.sh

# 1. Generate configuration file for affine
AFFINE_ROOT=${ATLAS_OUT_ROOT}/affine
mkdir -p ${AFFINE_ROOT}
AFFINE_CONFIG=${AFFINE_ROOT}/config.sh
#generate_bash_config_scan \
#  ${AFFINE_CONFIG} \
#  ${IN_DATA_FOLDER} \
#  ${AFFINE_ROOT} \
#  ${REFERENCE_THRES_IMG}

# 2. Execute affine.
#${AFFINE_SRC_ROOT}/run_reg_block.sh ${AFFINE_CONFIG}

# 3. Post-process affine result.
NON_RIGID_ROOT=${ATLAS_OUT_ROOT}/non_rigid
mkdir -p ${NON_RIGID_ROOT}
NON_RIGID_INPUT_FOLDER=${NON_RIGID_ROOT}/affine_result
post_process_affine \
  ${AFFINE_ROOT}/interp/ori \
  ${TEMPLATE_MASK_IMG} \
  ${NON_RIGID_INPUT_FOLDER}

# 4. Now do non-rigid with deeds
NON_RIGID_OUT_TEMP_FOLDER=${NON_RIGID_ROOT}/temp
NON_RIGID_OUT_WRAPPED_FOLDER=${NON_RIGID_ROOT}/wrapped
run_deeds_non_rigid \
  ${NON_RIGID_INPUT_FOLDER} \
  ${NON_RIGID_OUT_TEMP_FOLDER} \
  ${NON_RIGID_OUT_WRAPPED_FOLDER} \
  ${REFERENCE_ROI_MASKED_IMG} \
  ${IDD_MAT}

# 5. Generate the atlas
OUT_TEMPLATE=${ATLAS_OUT_ROOT}/template/100_template.nii.gz
set -o xtrace
${PYTHON_ENV} ${NON_RIGID_SRC_ROOT}/tools/average_images.py \
  --in_folder ${NON_RIGID_OUT_WRAPPED_FOLDER} \
  --out ${OUT_TEMPLATE} \
  --ref ${REFERENCE_ROI_MASKED_IMG} \
  --num_processes 10
set +o xtrace

end=`date +%s`
runtime=$((end-start))
echo "Complete! Total ${runtime} (s)"