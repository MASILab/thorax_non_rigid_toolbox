###################### Change Log ################
# 3/17/2020 - Kaiwen
# Create gender specified 100 atlas
##################################################

ATLAS_PROJ_NAME=20200317_gender_sep_atlas

# Runtime enviroment
NON_RIGID_SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxNonRigid
AFFINE_SRC_ROOT=/home-nfs2/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxAffine_for_non_rigid
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python

# Tools
TOOL_ROOT=${NON_RIGID_SRC_ROOT}/packages
DCM_2_NII_TOOL=${TOOL_ROOT}/dcm2niix
C3D_ROOT=${TOOL_ROOT}/c3d
NIFYREG_ROOT=${TOOL_ROOT}/niftyreg/bin
DEEDS_ROOT=${TOOL_ROOT}/deedsBCV
REG_TOOL_ROOT=${DEEDS_ROOT}

# Data
DATA_ROOT=/nfs/masi/xuk9/SPORE
ATLAS_OUT_ROOT=${DATA_ROOT}/registration/non_rigid_atlas/${ATLAS_PROJ_NAME}
IN_DATA_FOLDER=${DATA_ROOT}/data/data_flat
MALE_FLAG="male"
FEMALE_FLAG="female"

# Preprocessing
SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=450
DIM_Y=450
DIM_Z=400

REFERENCE_FOLDER=${ATLAS_OUT_ROOT}/data/reference
#REFERENCE_THRES_IMG=${REFERENCE_FOLDER}/00000825time20170929_thres.nii.gz # For niftyreg affine
#REFERENCE_ROI_MASKED_IMG=${REFERENCE_FOLDER}/00000825time20170929_roi_masked.nii.gz # for deeds non-rigid
TEMPLATE_MASK_IMG=${REFERENCE_FOLDER}/roi_mask.nii.gz
IDD_MAT=${REFERENCE_FOLDER}/idendity_matrix.txt