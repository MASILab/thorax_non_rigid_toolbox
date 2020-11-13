#!/bin/bash

##################################################
# 2/6/2020 - Kaiwen
# Run niftyreg pipeline for label propagation.
# Input:
# 1. Folder for diconm folders (diconm will be in each subfolder).
# 2. Folder to output
# Output:
# 1. Generated label file for each target.
# Procedure:
# 1. Convert dicomn to nii.gz
# 2. Preprocess nii.gz without re-center to origin (we need to overlapping with the original image)
# 3. Run registration to atlas
# 4. Revert label transformation fields.
# 5. Apply reverted transformation to atlas label.
# 6. Resample label maps to original images using reg_resample.
##################################################

in_folder=$(readlink -f $1)
out_folder=$(readlink -f $2)
num_preprocess="$3"

PYTHON_ENV=/opt/conda/envs/python37/bin/python

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_ROOT=${BASH_DIR}

bash_config_file=${BASH_DIR}/bash_config/niftyreg_singularity_env.sh
${PYTHON_ENV} ${SRC_ROOT}/tools/create_config_file.py --config-path ${bash_config_file} --num-processes ${num_preprocess}

echo "Non-rigid pipeline, from atlas to images"
echo "Loading bash config from ${bash_config_file}"
source ${bash_config_file}
source ${SRC_ROOT}/tools/reg_preprocess_functions.sh
source ${SRC_ROOT}/tools/reg_registration_functions.sh
source ${SRC_ROOT}/tools/reg_interpolation_functions.sh

start=`date +%s`

# Step.1 convert dicom to nii
NII_FOLDER=${OUT_ROOT}/out/nii_data
mkdir -p ${NII_FOLDER}
#convert_dicom_nii_folder ${in_folder} ${NII_FOLDER}

# Step.2 preprocess
PREPROCESS_FOLDER=${OUT_ROOT}/preprocess
mkdir -p ${PREPROCESS_FOLDER}
#${SRC_ROOT}/tools/run_preprocess_folder.sh ${NII_FOLDER} ${PREPROCESS_FOLDER} ${bash_config_file}

# Step.3 registration to atlas
REG_RESULT_ROOT=${OUT_ROOT}/reg
mkdir -p ${REG_RESULT_ROOT}
non_rigid_niftyreg_folder ${PREPROCESS_FOLDER} ${IMAGE_ATLAS} ${REG_RESULT_ROOT}

# Step.4 & 5 revert transformation fields then apply to label
FOLDER_TRANS=${REG_RESULT_ROOT}/trans
INTERP_RESULT_ROOT=${OUT_ROOT}/interp
mkdir -p ${INTERP_RESULT_ROOT}
interp_non_rigid_label_inverse_wrap_niftyreg_folder ${FOLDER_TRANS} ${IMAGE_LABEL} ${PREPROCESS_FOLDER} ${INTERP_RESULT_ROOT}

# Step.6 resample labels to target image space.
LABEL_FOLDER=${INTERP_RESULT_ROOT}/interp_label
TARGE_FOLDER=${NII_FOLDER}
RESAMPLE_LABEL_FOLDER=${out_folder}/out/label_data
mkdir -p ${RESAMPLE_LABEL_FOLDER}
interp_identity_resample_niftyreg_folder ${LABEL_FOLDER} ${TARGE_FOLDER} ${RESAMPLE_LABEL_FOLDER}

end=`date +%s`
runtime=$((end-start))
echo "Complete! Total ${runtime} (s)"