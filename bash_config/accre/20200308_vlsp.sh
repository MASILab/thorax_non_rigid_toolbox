###################### Change Log ################
# 3/8/2020 - Kaiwen
# Non-rigid part for deeds atlas built over vlsp.
# Use the affine result (interp) as input.
##################################################

PROJ_NAME=20200308_vlsp

# Runtime enviroment
SRC_ROOT=/home/xuk9/src/ThoraxNonRigid_vlsp
PYTHON_ENV=/home/xuk9/.conda/envs/python37/bin/python

# Tools
TOOL_ROOT=${SRC_ROOT}/packages
DCM_2_NII_TOOL=${TOOL_ROOT}/dcm2niix
C3D_ROOT=${TOOL_ROOT}/c3d
NIFYREG_ROOT=${TOOL_ROOT}/niftyreg/bin
#=${TOOL_ROOT}/deedsBCV
DEEDS_ROOT=/home/xuk9/src/deedsBCV_masi
REG_TOOL_ROOT=${DEEDS_ROOT}

DEEDS_ARGS="-ln 4 -G 7x6x5x4 -L 7x6x5x4 -Q 4x3x2x1"

# Data
DATA_ROOT=/home/xuk9/Data/SPORE
PROJ_ROOT=${DATA_ROOT}/registration/non_rigid_niftyreg_deeds/${PROJ_NAME}
IN_DATA_FOLDER=${PROJ_ROOT}/affine/interp/ori # Output from affine step
OUT_DATA_FOLDER=${PROJ_ROOT}/non_rigid
OUT_MASKED_INPUT_FOLDER=${OUT_DATA_FOLDER}/interp_masked
OUT_DEEDS_OUTPUT_FOLDER=${OUT_DATA_FOLDER}/deeds_output
OUT_WRAPPED_FOLDER=${OUT_DATA_FOLDER}/wrapped
FILE_LIST_TXT=${DATA_ROOT}/nii_list.txt
NUMBER_SCAN=1473

# Accre
SLURM_BATCH_FILE=${OUT_DATA_FOLDER}/run_accre_non_rigid.sh
SLURM_LOG_FOLDER=${OUT_DATA_FOLDER}/log

# References
REFERENCE_FOLDER=${PROJ_ROOT}/atlas
REFERENCE_IMG=${REFERENCE_FOLDER}/100_template.nii.gz # original intensity without thres
ROI_MASK_IMG=${REFERENCE_FOLDER}/roi_mask.nii.gz
IDD_MAT=${REFERENCE_FOLDER}/idendity_matrix.txt

# Preprocessing
SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=450
DIM_Y=450
DIM_Z=400