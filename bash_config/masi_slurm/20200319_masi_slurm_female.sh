###################### Change Log ################
# 3/19/2020 - Kaiwen
# Run on masi space with slurm
##################################################

PROJ_NAME=20200317_gender_vlsp

#GENDER_FLAG="male"
GENDER_FLAG="female"

# Runtime enviroment
SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/03-Thorax-FL/src/ThoraxNonRigid
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python

# Tools
TOOL_ROOT=${SRC_ROOT}/packages
DCM_2_NII_TOOL=${TOOL_ROOT}/dcm2niix
C3D_ROOT=${TOOL_ROOT}/c3d
NIFYREG_ROOT=${TOOL_ROOT}/niftyreg/bin
DEEDS_ROOT=${TOOL_ROOT}/deedsBCV
REG_TOOL_ROOT=${DEEDS_ROOT}

#DEEDS_ARGS="-ln 4 -G 7x6x5x4 -L 7x6x5x4 -Q 4x3x2x1"

# Data
DATA_ROOT=/nfs/masi/xuk9/SPORE
PROJ_ROOT=${DATA_ROOT}/registration/non_rigid_vlsp/${PROJ_NAME}/${GENDER_FLAG}
IN_DATA_FOLDER=${PROJ_ROOT}/affine/interp/ori # Output from affine step
OUT_DATA_FOLDER=${PROJ_ROOT}/non_rigid

PREPROCESS_ROOT=${OUT_DATA_FOLDER}/preprocess
OUT_MASKED_INPUT_FOLDER=${PREPROCESS_ROOT}/interp_masked
OUT_NON_NAN_FOLDER=${PREPROCESS_ROOT}/non_nan
OUT_DEEDS_OUTPUT_FOLDER=${OUT_DATA_FOLDER}/deeds_output
OUT_WRAPPED_FOLDER=${OUT_DATA_FOLDER}/wrapped
FILE_LIST_TXT=/nfs/masi/xuk9/SPORE/data/file_list/${GENDER_FLAG}.txt
NUMBER_SCAN=650

# SLUMR
SLURM_BATCH_FILE=${OUT_DATA_FOLDER}/run_accre_non_rigid.sh
SLURM_LOG_FOLDER=${OUT_DATA_FOLDER}/log

# References
REFERENCE_FOLDER=${PROJ_ROOT}/../template
REFERENCE_IMG=${REFERENCE_FOLDER}/${GENDER_FLAG}.nii.gz # original intensity without thres
ROI_MASK_IMG=${REFERENCE_FOLDER}/roi_mask.nii.gz
IDD_MAT=${REFERENCE_FOLDER}/idendity_matrix.txt

# Preprocessing
SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=450
DIM_Y=450
DIM_Z=400