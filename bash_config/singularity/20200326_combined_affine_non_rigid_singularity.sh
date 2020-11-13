###################### Change Log ################
# 3/26 - Kaiwen
# This is an example of how a configuration file
# looks like to call the singularity. It should be
# put under specified location view from the singularity.
##################################################

# Runtime enviroment
NON_RIGID_SRC_ROOT=/src/Thorax_non_rigid_combine
AFFINE_SRC_ROOT=/src/Thorax_affine_combine
PYTHON_ENV=/opt/conda/envs/python37/bin/python

# Data
DATA_ROOT=/data_root
PROJ_ROOT=/proj_root
IN_DATA_FOLDER=${DATA_ROOT}

# Tools
TOOL_ROOT=${NON_RIGID_SRC_ROOT}/packages
DCM_2_NII_TOOL=${TOOL_ROOT}/dcm2niix
C3D_ROOT=${TOOL_ROOT}/c3d
NIFYREG_ROOT=${TOOL_ROOT}/niftyreg/bin
DEEDS_ROOT=${TOOL_ROOT}/deedsBCV
REG_TOOL_ROOT=${DEEDS_ROOT}

FSL_ROOT=/usr/local/fsl/bin
. ${FSL_ROOT}/../etc/fslconf/fsl.sh

# References
REFERENCE_FOLDER=${PROJ_ROOT}/reference
AFFINE_REFERENCE=${REFERENCE_FOLDER}/affine.nii.gz
NON_RIGID_REFERENCE=${REFERENCE_FOLDER}/non_rigid.nii.gz
ROI_MASK_IMG=${REFERENCE_FOLDER}/roi_mask.nii.gz
IDD_MAT=${REFERENCE_FOLDER}/idendity_matrix.txt

RUN_SCRIPT_PATH=${PROJ_ROOT}/run_combine_pipeline.sh